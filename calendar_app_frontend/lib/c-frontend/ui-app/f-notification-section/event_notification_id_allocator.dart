import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum EventNotificationKind {
  reminder,
  start,
}

/// Assigns stable local-notification IDs to event notification kinds.
///
/// IDs are persisted instead of derived from [String.hashCode], because hash
/// codes can collide and are not stable across app restarts.
class EventNotificationIdAllocator {
  EventNotificationIdAllocator({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const _storageKey = 'event_notification_id_allocations_v1';
  static const _maxNotificationId = 2147483647;

  final Future<SharedPreferences> Function() _preferences;
  Future<void> _pending = Future.value();

  Future<int> idFor({
    required String eventId,
    required EventNotificationKind kind,
  }) {
    final result = _pending.then((_) => _allocate(eventId, kind));
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<int> _allocate(String eventId, EventNotificationKind kind) async {
    final preferences = await _preferences();
    final stored = _StoredAllocations.fromJson(
      preferences.getString(_storageKey),
    );
    final key = jsonEncode(<String>[eventId, kind.name]);
    final existingId = stored.idsByKey[key];

    if (existingId != null &&
        existingId > 0 &&
        existingId <= _maxNotificationId &&
        stored.idsByKey.values.where((id) => id == existingId).length == 1) {
      return existingId;
    }

    final usedIds = stored.idsByKey.values.toSet();
    var candidate = stored.nextId;
    while (usedIds.contains(candidate)) {
      candidate = _next(candidate);
    }

    stored.idsByKey[key] = candidate;
    stored.nextId = _next(candidate);
    await preferences.setString(_storageKey, stored.toJson());
    return candidate;
  }

  int _next(int id) => id >= _maxNotificationId ? 1 : id + 1;
}

final eventNotificationIdAllocator = EventNotificationIdAllocator();

class _StoredAllocations {
  _StoredAllocations({required this.idsByKey, required this.nextId});

  factory _StoredAllocations.fromJson(String? value) {
    if (value == null) {
      return _StoredAllocations(idsByKey: <String, int>{}, nextId: 1);
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final rawIds = decoded['ids'];
      final ids = <String, int>{};
      if (rawIds is Map) {
        rawIds.forEach((key, value) {
          if (key is String && value is int) ids[key] = value;
        });
      }
      final nextId = decoded['nextId'];
      return _StoredAllocations(
        idsByKey: ids,
        nextId: nextId is int &&
                nextId > 0 &&
                nextId <= EventNotificationIdAllocator._maxNotificationId
            ? nextId
            : 1,
      );
    } catch (_) {
      return _StoredAllocations(idsByKey: <String, int>{}, nextId: 1);
    }
  }

  final Map<String, int> idsByKey;
  int nextId;

  String toJson() => jsonEncode(<String, dynamic>{
        'ids': idsByKey,
        'nextId': nextId,
      });
}
