import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:hexora/a-models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/i_time_tracking_api_client.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';

class LocationTrackingPermissionException implements Exception {
  const LocationTrackingPermissionException(this.message,
      {this.openSettings = false});

  final String message;
  final bool openSettings;

  @override
  String toString() => message;
}

class GeofencedVisitTrackingService extends ChangeNotifier {
  GeofencedVisitTrackingService({
    required ITimeTrackingApiClient api,
    required UserDomain userDomain,
  })  : _api = api,
        _userDomain = userDomain {
    _userDomain.addListener(_handleUserChanged);
  }

  static const _sessionKey = 'geofenced_visit_tracking_session_v1';
  static const _deviceIdKey = 'geofenced_visit_tracking_device_id_v1';
  static const _pendingEventsKey = 'geofenced_visit_pending_events_v1';
  static const _insideStateKey = 'geofenced_visit_inside_state_v1';
  static const _participantsKey = 'geofenced_visit_participants_v1';
  static const _uuid = Uuid();

  final ITimeTrackingApiClient _api;
  final UserDomain _userDomain;
  StreamSubscription<Position>? _positionSubscription;
  LocationTrackingSession? _session;
  List<ClientServiceLocation> _locations = const <ClientServiceLocation>[];
  final Map<String, bool> _insideByClient = <String, bool>{};
  bool _restored = false;
  bool _busy = false;
  bool _streamActive = false;
  bool _processingPosition = false;
  Future<void> _eventOperations = Future<void>.value();
  String? _error;
  double? _lastAccuracyMeters;
  DateTime? _lastEventAt;
  List<String> _participantWorkerIds = const <String>[];
  LocationBoundaryEvent? _rejectedArrivalEvent;

  LocationTrackingSession? get session => _session;
  bool get isActive => _session != null;
  bool get isBusy => _busy;
  bool get isStreamActive => _streamActive;
  String? get error => _error;
  int get clientLocationCount => _locations.length;
  double? get lastAccuracyMeters => _lastAccuracyMeters;
  DateTime? get lastEventAt => _lastEventAt;
  List<String> get participantWorkerIds => _participantWorkerIds;
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final restored = LocationTrackingSession.fromStoredJson(
        Map<String, dynamic>.from(decoded),
      );
      if (restored.id.isEmpty || restored.groupId.isEmpty) return;
      _session = restored;
      await _restoreInsideState(prefs);
      await _restoreParticipants(prefs, restored.groupId);
      notifyListeners();
      if (_userDomain.user != null) {
        await resume(requestPermission: false);
      }
    } catch (error) {
      _error = visitTrackingErrorMessage(error) ?? error.toString();
      notifyListeners();
    }
  }

  Future<void> start(
    String groupId, {
    Iterable<String> participantWorkerIds = const <String>[],
  }) async {
    if (_busy) return;
    if (!isSupported) {
      throw const LocationTrackingPermissionException(
        'Background visit tracking is available only on Android and iOS.',
      );
    }
    final normalizedGroupId = groupId.trim();
    if (normalizedGroupId.isEmpty) return;
    await updateParticipantWorkers(
      normalizedGroupId,
      participantWorkerIds,
    );
    if (_session != null) {
      if (_session!.groupId == normalizedGroupId && !_streamActive) {
        await resume(requestPermission: true);
        return;
      }
      throw StateError('Another location tracking session is already active.');
    }

    _busy = true;
    _error = null;
    notifyListeners();
    LocationTrackingSession? started;
    try {
      await _ensureBackgroundPermission(request: true);
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await _deviceId(prefs);
      final platform =
          defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';
      final token = await _userDomain.getAuthToken();
      started = await _api.startLocationTracking(
        normalizedGroupId,
        token,
        deviceId: deviceId,
        platform: platform,
      );
      _locations = await _api.getClientLocations(normalizedGroupId, token);
      _session = started;
      _insideByClient.clear();
      await prefs.remove(_insideStateKey);
      await _persistSession(prefs);
      await _startPositionStream();
      await _flushPendingEvents();
    } catch (error) {
      if (started != null && _session == null) {
        try {
          final token = await _userDomain.getAuthToken();
          await _api.stopLocationTracking(
            normalizedGroupId,
            started.id,
            token,
          );
        } catch (_) {}
      }
      _error = visitTrackingErrorMessage(error) ?? error.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> resume({bool requestPermission = true}) async {
    final current = _session;
    if (_busy || current == null || _streamActive) return;
    if (!isSupported) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureBackgroundPermission(request: requestPermission);
      final token = await _userDomain.getAuthToken();
      _locations = await _api.getClientLocations(current.groupId, token);
      await _startPositionStream();
      await _flushPendingEvents();
    } catch (error) {
      _error = visitTrackingErrorMessage(error) ?? error.toString();
      if (requestPermission) rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final current = _session;
    if (_busy || current == null) return;
    _busy = true;
    _error = null;
    notifyListeners();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _streamActive = false;
    try {
      await _flushPendingEvents();
      final token = await _userDomain.getAuthToken();
      await _api.stopLocationTracking(
        current.groupId,
        current.id,
        token,
      );
      _session = null;
      _locations = const <ClientServiceLocation>[];
      _insideByClient.clear();
      _participantWorkerIds = const <String>[];
      _rejectedArrivalEvent = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_insideStateKey);
      await prefs.remove(_participantsKey);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  void _handleUserChanged() {
    if (_userDomain.user == null) {
      unawaited(_positionSubscription?.cancel());
      _positionSubscription = null;
      _streamActive = false;
      notifyListeners();
      return;
    }
    if (_session != null && !_streamActive && !_busy) {
      unawaited(resume(requestPermission: false));
    }
  }

  Future<void> _ensureBackgroundPermission({required bool request}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationTrackingPermissionException(
        'Location services are disabled on this device.',
        openSettings: true,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (request && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (request && permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationTrackingPermissionException(
        'Location permission is permanently denied. Enable it in system settings.',
        openSettings: true,
      );
    }
    if (permission != LocationPermission.always) {
      throw const LocationTrackingPermissionException(
        'Allow location access all the time to track arrivals in the background.',
        openSettings: true,
      );
    }
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 20),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Seguimiento de visitas activo',
          notificationText:
              'Hexora detecta llegadas y salidas mientras la sesión está activa.',
          notificationChannelName: 'Seguimiento de visitas',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
      activityType: ActivityType.otherNavigation,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
      allowBackgroundLocationUpdates: true,
    );
  }

  Future<void> _startPositionStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen(
      (position) => unawaited(_handlePosition(position)),
      onError: (Object error) {
        _streamActive = false;
        _error = error.toString();
        notifyListeners();
      },
      cancelOnError: false,
    );
    _streamActive = true;
  }

  Future<void> _handlePosition(Position position) async {
    final current = _session;
    if (_busy ||
        _processingPosition ||
        current == null ||
        position.accuracy > 100) {
      return;
    }
    _processingPosition = true;
    try {
      _lastAccuracyMeters = position.accuracy;
      await _flushPendingEvents();

      for (final location in _locations) {
        if (_busy || _session?.id != current.id) return;
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );
        final isInside = distance <= location.radiusMeters;
        final previous = _insideByClient[location.clientId];
        if (previous == isInside) continue;
        _insideByClient[location.clientId] = isInside;
        await _persistInsideState();
        if (previous == null && !isInside) continue;

        final event = LocationBoundaryEvent(
          trackingSessionId: current.id,
          eventId: _uuid.v4(),
          clientId: location.clientId,
          eventType: isInside ? 'arrival' : 'departure',
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          recordedAt: position.timestamp.toUtc(),
          participantWorkerIds:
              isInside ? _participantWorkerIds : const <String>[],
        );
        await _queueAndSend(event);
      }
      notifyListeners();
    } finally {
      _processingPosition = false;
    }
  }

  Future<void> _queueAndSend(LocationBoundaryEvent event) async {
    await _runEventOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      final pending = _readPendingEvents(prefs)..add(event);
      await _writePendingEvents(prefs, pending);
      await _flushPendingEventsUnsafe();
    });
  }

  Future<void> _flushPendingEvents() =>
      _runEventOperation(_flushPendingEventsUnsafe);

  Future<void> _flushPendingEventsUnsafe() async {
    final current = _session;
    if (current == null) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = _readPendingEvents(prefs);
    if (pending.isEmpty) return;
    final remaining = <LocationBoundaryEvent>[];
    String? token;
    try {
      token = await _userDomain.getAuthToken();
    } catch (_) {
      return;
    }
    for (final event in pending) {
      if (event.trackingSessionId != current.id) continue;
      try {
        await _api.sendLocationEvent(current.groupId, token, event);
        _lastEventAt = event.recordedAt;
        if (_rejectedArrivalEvent?.eventId == event.eventId) {
          _rejectedArrivalEvent = null;
        }
      } on BackendApiException catch (error) {
        final message = visitTrackingErrorMessage(error);
        final rejected = message != null;
        if (rejected) {
          _error = message;
          if (event.eventType == 'arrival') _rejectedArrivalEvent = event;
          notifyListeners();
        } else if (error.statusCode != 409) {
          remaining.add(event);
        }
      } catch (_) {
        remaining.add(event);
      }
    }
    await _writePendingEvents(prefs, remaining);
  }

  Future<void> _runEventOperation(Future<void> Function() operation) {
    final next = _eventOperations.then((_) => operation());
    _eventOperations = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return next;
  }

  List<LocationBoundaryEvent> _readPendingEvents(SharedPreferences prefs) {
    final raw = prefs.getString(_pendingEventsKey);
    if (raw == null || raw.trim().isEmpty) return <LocationBoundaryEvent>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <LocationBoundaryEvent>[];
      return decoded
          .whereType<Map>()
          .map((item) => LocationBoundaryEvent.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return <LocationBoundaryEvent>[];
    }
  }

  Future<void> _writePendingEvents(
    SharedPreferences prefs,
    List<LocationBoundaryEvent> events,
  ) async {
    await prefs.setString(
      _pendingEventsKey,
      jsonEncode(events.map((event) => event.toJson()).toList()),
    );
  }

  Future<void> _persistSession(SharedPreferences prefs) async {
    final current = _session;
    if (current == null) return;
    await prefs.setString(_sessionKey, jsonEncode(current.toJson()));
  }

  Future<void> _restoreInsideState(SharedPreferences prefs) async {
    final raw = prefs.getString(_insideStateKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _insideByClient
        ..clear()
        ..addAll(decoded.map(
          (key, value) => MapEntry(key.toString(), value == true),
        ));
    } catch (_) {}
  }

  Future<void> _persistInsideState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_insideStateKey, jsonEncode(_insideByClient));
  }

  Future<void> updateParticipantWorkers(
    String groupId,
    Iterable<String> workerIds,
  ) async {
    final normalized = <String>[];
    final seen = <String>{};
    for (final rawId in workerIds) {
      final id = rawId.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      if (normalized.length == 20) {
        throw ArgumentError(
            'A visit can have at most 20 accompanying workers.');
      }
      normalized.add(id);
    }
    _participantWorkerIds = List<String>.unmodifiable(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _participantsKey,
      jsonEncode(<String, dynamic>{
        'groupId': groupId.trim(),
        'workerIds': _participantWorkerIds,
      }),
    );
    notifyListeners();
    final rejected = _rejectedArrivalEvent;
    if (rejected != null && _session?.groupId == groupId.trim()) {
      _rejectedArrivalEvent = null;
      await _queueAndSend(
        LocationBoundaryEvent(
          trackingSessionId: rejected.trackingSessionId,
          eventId: rejected.eventId,
          clientId: rejected.clientId,
          eventType: rejected.eventType,
          latitude: rejected.latitude,
          longitude: rejected.longitude,
          accuracyMeters: rejected.accuracyMeters,
          recordedAt: rejected.recordedAt,
          source: rejected.source,
          participantWorkerIds: _participantWorkerIds,
        ),
      );
    }
  }

  Future<void> _restoreParticipants(
    SharedPreferences prefs,
    String groupId,
  ) async {
    final raw = prefs.getString(_participantsKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['groupId']?.toString() != groupId) return;
      final values = decoded['workerIds'];
      if (values is! List) return;
      _participantWorkerIds = values
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .take(20)
          .toList(growable: false);
    } catch (_) {}
  }

  Future<String> _deviceId(SharedPreferences prefs) async {
    final existing = prefs.getString(_deviceIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _uuid.v4();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  @override
  void dispose() {
    _userDomain.removeListener(_handleUserChanged);
    unawaited(_positionSubscription?.cancel());
    super.dispose();
  }
}

String? visitTrackingErrorMessage(Object error) {
  if (error is! BackendApiException) return null;
  return switch (error.code) {
    'INVALID_VISIT_PARTICIPANT' =>
      'Uno de los acompa\u00f1antes ya no es un trabajador activo.',
    'WORKER_ACTIVE_VISIT_EXISTS' =>
      'Uno de los trabajadores seleccionados ya participa en otra visita activa.',
    'ACTIVE_VISIT_EXISTS' => 'Ya participas en otra visita activa.',
    'WORKER_PROFILE_REQUIRED' =>
      'Tu usuario todav\u00eda no est\u00e1 vinculado a un trabajador activo.',
    _ => null,
  };
}
