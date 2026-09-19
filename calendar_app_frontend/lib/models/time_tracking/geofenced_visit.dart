class ClientServiceLocation {
  const ClientServiceLocation({
    required this.clientId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.clientName,
    this.label,
    this.isEnabled = true,
  });

  final String clientId;
  final String? clientName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? label;
  final bool isEnabled;

  factory ClientServiceLocation.fromJson(Map<String, dynamic> json) {
    final client = json['client'] is Map
        ? Map<String, dynamic>.from(json['client'] as Map)
        : const <String, dynamic>{};
    final rawLocation = json['serviceLocation'] ??
        json['location'] ??
        client['serviceLocation'];
    final nested =
        rawLocation is Map ? Map<String, dynamic>.from(rawLocation) : json;
    return ClientServiceLocation(
      clientId: _identifier(
        json['clientId'] ??
            client['_id'] ??
            client['id'] ??
            json['_id'] ??
            json['id'],
      ),
      clientName: _optionalText(
        json['clientName'] ?? client['name'] ?? json['name'],
      ),
      latitude: _number(nested['latitude']),
      longitude: _number(nested['longitude']),
      radiusMeters: _number(nested['radiusMeters'], fallback: 75),
      label: _optionalText(nested['label']),
      isEnabled: _boolean(nested['isEnabled'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'clientId': clientId,
        if (clientName != null) 'clientName': clientName,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        if (label != null) 'label': label,
        'isEnabled': isEnabled,
      };
}

class LocationTrackingSession {
  const LocationTrackingSession({
    required this.id,
    required this.groupId,
    required this.deviceId,
    required this.platform,
    this.startedAt,
  });

  final String id;
  final String groupId;
  final String deviceId;
  final String platform;
  final DateTime? startedAt;

  factory LocationTrackingSession.fromJson(
    Map<String, dynamic> json, {
    required String fallbackGroupId,
    required String fallbackDeviceId,
    required String fallbackPlatform,
  }) {
    final source = _nestedEnvelope(
      json,
      const <String>['trackingSession', 'session', 'data', 'item'],
    );
    return LocationTrackingSession(
      id: _text(
        source['trackingSessionId'] ??
            source['sessionId'] ??
            source['_id'] ??
            source['id'],
      ),
      groupId: _text(source['groupId'], fallback: fallbackGroupId),
      deviceId: _text(source['deviceId'], fallback: fallbackDeviceId),
      platform: _text(source['platform'], fallback: fallbackPlatform),
      startedAt: _date(source['startedAt'] ?? source['createdAt']),
    );
  }

  factory LocationTrackingSession.fromStoredJson(Map<String, dynamic> json) =>
      LocationTrackingSession(
        id: _text(json['id']),
        groupId: _text(json['groupId']),
        deviceId: _text(json['deviceId']),
        platform: _text(json['platform']),
        startedAt: _date(json['startedAt']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'groupId': groupId,
        'deviceId': deviceId,
        'platform': platform,
        if (startedAt != null)
          'startedAt': startedAt!.toUtc().toIso8601String(),
      };
}

class LocationBoundaryEvent {
  const LocationBoundaryEvent({
    required this.trackingSessionId,
    required this.eventId,
    required this.clientId,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
    this.source = 'background_geofence',
    this.participantWorkerIds = const <String>[],
  });

  final String trackingSessionId;
  final String eventId;
  final String clientId;
  final String eventType;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime recordedAt;
  final String source;
  final List<String> participantWorkerIds;

  factory LocationBoundaryEvent.fromJson(Map<String, dynamic> json) =>
      LocationBoundaryEvent(
        trackingSessionId: _text(json['trackingSessionId']),
        eventId: _text(json['eventId']),
        clientId: _text(json['clientId']),
        eventType: _text(json['eventType']),
        latitude: _number(json['latitude']),
        longitude: _number(json['longitude']),
        accuracyMeters: _number(json['accuracyMeters']),
        recordedAt: _date(json['recordedAt']) ?? DateTime.now().toUtc(),
        source: _text(json['source'], fallback: 'background_geofence'),
        participantWorkerIds: _stringList(json['participantWorkerIds']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'trackingSessionId': trackingSessionId,
        'eventId': eventId,
        'clientId': clientId,
        'eventType': eventType,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'source': source,
        if (eventType == 'arrival' && participantWorkerIds.isNotEmpty)
          'participantWorkerIds': _stringList(participantWorkerIds),
      };
}

class VisitWorkerSummary {
  const VisitWorkerSummary({
    required this.id,
    this.displayName,
    this.userId,
  });

  final String id;
  final String? displayName;
  final String? userId;

  factory VisitWorkerSummary.fromJson(dynamic raw) {
    if (raw is Map) {
      final json = Map<String, dynamic>.from(raw);
      return VisitWorkerSummary(
        id: _identifier(json['_id'] ?? json['id']),
        displayName: _optionalText(json['displayName'] ?? json['name']),
        userId: _identifierOrNull(json['userId']),
      );
    }
    return VisitWorkerSummary(id: _identifier(raw));
  }
}

class WorkerVisit {
  const WorkerVisit({
    required this.id,
    required this.clientId,
    this.clientName,
    this.workerId,
    this.workerName,
    this.arrivedAt,
    this.departedAt,
    this.durationMinutes,
    this.status,
    this.responsibleWorker,
    this.participantWorkers = const <VisitWorkerSummary>[],
    this.recordedByUserId,
    this.lastSeenAt,
    this.source,
  });

  final String id;
  final String clientId;
  final String? clientName;
  final String? workerId;
  final String? workerName;
  final DateTime? arrivedAt;
  final DateTime? departedAt;
  final int? durationMinutes;
  final String? status;
  final VisitWorkerSummary? responsibleWorker;
  final List<VisitWorkerSummary> participantWorkers;
  final String? recordedByUserId;
  final DateTime? lastSeenAt;
  final String? source;

  int get teamSize => 1 + participantWorkers.length;

  factory WorkerVisit.fromJson(Map<String, dynamic> json) {
    final rawClient = json['clientId'] is Map
        ? json['clientId']
        : json['client'] ?? json['clientId'];
    final client = rawClient is Map
        ? Map<String, dynamic>.from(rawClient)
        : const <String, dynamic>{};
    final rawWorker = json['workerId'] is Map
        ? json['workerId']
        : json['worker'] ?? json['workerId'];
    final worker = VisitWorkerSummary.fromJson(rawWorker);
    final participants = json['participantWorkerIds'] is List
        ? (json['participantWorkerIds'] as List)
            .map(VisitWorkerSummary.fromJson)
            .where((item) => item.id.isNotEmpty)
            .toList(growable: false)
        : const <VisitWorkerSummary>[];
    final arrivedAt = _date(
      json['arrivedAt'] ??
          json['arrivalAt'] ??
          json['arrival'] ??
          json['startedAt'],
    );
    final departedAt = _date(
      json['departedAt'] ??
          json['departureAt'] ??
          json['departure'] ??
          json['endedAt'],
    );
    final rawDuration = json['durationMinutes'] ?? json['duration'];
    return WorkerVisit(
      id: _text(json['_id'] ?? json['id'] ?? json['visitId']),
      clientId: _identifier(client['_id'] ?? client['id'] ?? rawClient),
      clientName: _optionalText(json['clientName'] ?? client['name']),
      workerId: worker.id.isEmpty ? null : worker.id,
      workerName: _optionalText(json['workerName']) ?? worker.displayName,
      arrivedAt: arrivedAt,
      departedAt: departedAt,
      durationMinutes: rawDuration is num
          ? rawDuration.round()
          : int.tryParse(rawDuration?.toString() ?? ''),
      status: _optionalText(json['status']),
      responsibleWorker: worker.id.isEmpty ? null : worker,
      participantWorkers: participants,
      recordedByUserId: _identifierOrNull(json['recordedByUserId']),
      lastSeenAt: _date(json['lastSeenAt']),
      source: _optionalText(json['source']),
    );
  }
}

Map<String, dynamic> _nestedEnvelope(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return json;
}

String _text(dynamic value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

String _identifier(dynamic value) {
  if (value is Map) {
    return _text(value[r'$oid'] ?? value['_id'] ?? value['id']);
  }
  return _text(value);
}

String? _identifierOrNull(dynamic value) {
  final result = _identifier(value);
  return result.isEmpty ? null : result;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const <String>[];
  final seen = <String>{};
  return value
      .map(_identifier)
      .where((item) => item.isNotEmpty && seen.add(item))
      .toList(growable: false);
}

String? _optionalText(dynamic value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}

double _number(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolean(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

DateTime? _date(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
