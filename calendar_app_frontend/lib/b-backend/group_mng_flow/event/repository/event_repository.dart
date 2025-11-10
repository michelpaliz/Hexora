// lib/b-backend/core/event/repository/event_repository.dart
import 'dart:async';

import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/event/api/i_event_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/string_utils.dart';

class EventRepository implements IEventRepository {
  EventRepository({
    required IEventApiClient apiClient,
    required TokenSupplier tokenSupplier,
  })  : _api = apiClient,
        _token = tokenSupplier;

  final IEventApiClient _api;
  final TokenSupplier _token;

  // ---- In-memory cache + per-group streams ---------------------------------
  final Map<String, List<Event>> _cacheByGroupId = {};
  final Map<String, StreamController<List<Event>>> _controllers = {};

  StreamController<List<Event>> _ctrlFor(String groupId) =>
      _controllers.putIfAbsent(groupId, () => StreamController.broadcast());

  List<Event> _getCache(String groupId) =>
      _cacheByGroupId[groupId] ?? const <Event>[];

  void _emit(String groupId, List<Event> next) {
    _cacheByGroupId[groupId] = next;
    final c = _ctrlFor(groupId);
    if (!c.isClosed) c.add(List.unmodifiable(next));
  }

  // Dedupe by base id (handles instances vs series)
  List<Event> _dedupe(List<Event> list) =>
      {for (final e in list) baseId(e.id): e}.values.toList();

  // Helper: safe groupId
  String? _gidOf(Event e) {
    final gid = e.groupId;
    return (gid != null && gid.isNotEmpty) ? gid : null;
  }

  // ---- NEW: mutation serialization & buffering -----------------------------

  // ✅ NEW: serialize ops per group to keep transitions linear
  final Map<String, Future<void>> _ops = {}; // gid -> tail future

  Future<T> _queue<T>(String gid, Future<T> Function() op) {
    final prev = _ops[gid] ?? Future.value();
    final next = prev.then((_) => op());
    // keep chain alive even on error
    _ops[gid] = next.then((_) {}, onError: (_) {});
    return next;
  }

  // ✅ NEW: mark groups that are mid-refresh
  final Map<String, bool> _refreshing = {};

  // ✅ NEW: deltas that land while refreshing (replayed on the fresh snapshot)
  final Map<String, List<void Function(List<Event>)>> _pendingDeltas = {};

  // ✅ NEW: apply immediately or buffer if group is refreshing
  void _applyOrBuffer(String gid, void Function(List<Event>) apply) {
    if (_refreshing[gid] == true) {
      (_pendingDeltas[gid] ??= []).add(apply);
      return;
    }
    final list = [..._getCache(gid)];
    apply(list);
    _emit(gid, _dedupe(list));
  }

  // Public stream
  @override
  Stream<List<Event>> events$(String groupId) {
    final c = _ctrlFor(groupId);
    // emit snapshot to new listeners
    scheduleMicrotask(() {
      final snap = _getCache(groupId);
      if (snap.isNotEmpty && !c.isClosed) c.add(List.unmodifiable(snap));
    });
    return c.stream;
  }

  // ---- Refresh (authoritative) ---------------------------------------------
  @override
  Future<void> refreshGroup(String groupId) {
    // ✅ UPDATED: serialize refreshes and CRUD for this group
    return _queue(groupId, () async {
      _refreshing[groupId] = true; // ✅ NEW
      try {
        final token = await _token();
        final fetched = await _api.getEventsByGroupId(groupId, token);

        // Start from server snapshot
        var next = _dedupe(fetched);

        // ✅ NEW: apply any deltas that arrived during refresh
        final pending = _pendingDeltas[groupId];
        if (pending != null && pending.isNotEmpty) {
          for (final apply in pending) {
            apply(next);
          }
        }
        _pendingDeltas[groupId] = [];

        _emit(groupId, next);
      } finally {
        _refreshing[groupId] = false; // ✅ NEW (always clear)
      }
    });
  }

  // ---- CRUD (keeps cache in sync and emits) --------------------------------
  @override
  Future<Event> createEvent(Event event) {
    final gid = _gidOf(event) ?? '';
    return _queue(gid, () async {
      final token = await _token();
      final created = await _api.createEvent(event, token);
      final cid = _gidOf(created);
      if (cid != null) {
        _applyOrBuffer(cid, (list) => list.add(created)); // ✅ UPDATED
      }
      return created;
    });
  }

  @override
  Future<Event> getEventById(String id) async =>
      _api.getEventById(id, await _token());

  @override
  Future<Event> updateEvent(Event ev) {
    final gid = _gidOf(ev) ?? '';
    return _queue(gid, () async {
      final token = await _token();
      final updated = await _api.updateEvent(ev, token);
      final cid = _gidOf(updated);
      if (cid != null) {
        _applyOrBuffer(cid, (list) {
          for (var i = 0; i < list.length; i++) {
            if (baseId(list[i].id) == baseId(updated.id)) {
              list[i] = updated;
              return;
            }
          }
          list.add(updated); // upsert
        });
      }
      return updated;
    });
  }

  @override
  Future<Event> markEventAsDone(String id, {required bool isDone}) {
    // We don't know gid up front; serialize after we get the updated entity
    return _queue('__mark:$id', () async {
      // ✅ NEW: synthetic queue key
      final token = await _token();
      final updated =
          await _api.markEventAsDone(id, isDone: isDone, token: token);
      final cid = _gidOf(updated);
      if (cid != null) {
        _applyOrBuffer(cid, (list) {
          for (var i = 0; i < list.length; i++) {
            if (baseId(list[i].id) == baseId(updated.id)) {
              list[i] = updated;
              return;
            }
          }
          list.add(updated);
        });
      }
      return updated;
    });
  }

  @override
  Future<void> deleteEvent(String id) async {
    final token = await _token();
    await _api.deleteEvent(id, token);

    // We may not know the gid; remove from any group cache.
    final key = baseId(id);
    for (final gid in _cacheByGroupId.keys.toList()) {
      _applyOrBuffer(gid, (list) {
        list.removeWhere(
            (e) => baseId(e.id) == key || baseId(e.rawRuleId ?? '') == key);
      }); // ✅ UPDATED: will buffer if gid is mid-refresh
    }
  }

  @override
  Future<List<Event>> getEventsByGroupId(String groupId) async {
    // Keep this API call as-is to preserve your current domain usage pattern.
    final token = await _token();
    return _api.getEventsByGroupId(groupId, token);
  }

  // ---- Socket hooks (repo keeps cache in sync) ------------------------------
  @override
  void onSocketCreated(String groupId, Map<String, dynamic> json) {
    final created = Event.fromJson(json);
    final gid = _gidOf(created);
    if (gid == null || gid != groupId) return;
    _applyOrBuffer(groupId, (list) => list.add(created)); // ✅ UPDATED
  }

  @override
  void onSocketUpdated(String groupId, Map<String, dynamic> json) {
    final updated = Event.fromJson(json);
    final gid = _gidOf(updated);
    if (gid == null || gid != groupId) return;
    _applyOrBuffer(groupId, (list) {
      for (var i = 0; i < list.length; i++) {
        if (baseId(list[i].id) == baseId(updated.id)) {
          list[i] = updated;
          return;
        }
      }
      list.add(updated); // upsert
    }); // ✅ UPDATED
  }

  @override
  void onSocketDeleted(String groupId, Map<String, dynamic> json) {
    final deletedId = baseId(json['id']?.toString() ?? '');
    if (deletedId.isEmpty) return;
    _applyOrBuffer(groupId, (list) {
      list.removeWhere((e) =>
          baseId(e.id) == deletedId || baseId(e.rawRuleId ?? '') == deletedId);
    }); // ✅ UPDATED
  }

  // ---- Cleanup --------------------------------------------------------------
  void dispose() {
    for (final c in _controllers.values) {
      if (!c.isClosed) c.close();
    }
    _controllers.clear();
    _cacheByGroupId.clear();
  }
}
