// lib/b-backend/core/event/domain/event_domain.dart
import 'dart:async';
import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/resolver/event_group_resolver.dart';
import 'package:hexora/b-backend/group_mng_flow/event/string_utils.dart';
import 'package:hexora/b-backend/group_mng_flow/event/socket/socket_events.dart';
import 'package:hexora/b-backend/group_mng_flow/event/socket/socket_manager.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/event_notification_helper.dart';

typedef ReminderSynchronizer = Future<void> Function(
  BuildContext context,
  Event event, {
  bool showSchedulingStatus,
});

typedef ReminderCanceller = Future<void> Function(Event event);

class EventMutationResult {
  const EventMutationResult({
    required this.event,
    required this.reminderUnavailable,
  });

  final Event event;
  final bool reminderUnavailable;
}

class EventDomain {
  final Group _group;
  final IEventRepository _repo;
  final GroupEventResolver _resolver; // ðŸ‘ˆ resolver with cache
  final ReminderSynchronizer _syncReminder;
  final ReminderCanceller _cancelReminder;

  String get groupId => _group.id;

  final ValueNotifier<List<Event>> eventsNotifier =
      ValueNotifier<List<Event>>([]);

  void Function()? onExternalEventUpdate;

  bool _disposed = false;

  // refresh/loader guards
  bool _isRefreshing = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  void _setLoading(bool v) {
    if (_isLoading == v) return;
    _isLoading = v;
  }

  // repo subscription + debounce + external notify flag
  StreamSubscription<List<Event>>? _repoSub;
  Timer? _recomputeDebounce;
  bool _pendingExternalNotify = false;

  EventDomain(
    List<Event> initialEvents, {
    required BuildContext context,
    required Group group,
    required IEventRepository repository,
    required GroupDomain groupDomain,
    required GroupEventResolver resolver,
    ReminderSynchronizer? reminderSynchronizer,
    ReminderCanceller? reminderCanceller,
  })  : _group = group,
        _repo = repository,
        _resolver = resolver,
        _syncReminder = reminderSynchronizer ?? syncReminderFor,
        _cancelReminder = reminderCanceller ?? cancelReminderFor {
    _bootstrap(context, initialEvents);
    _setupSocketForwarding();

    // subscribe to the repository’s per-group stream
    _repoSub = _repo.events$(_group.id).listen((_) {
      final notify = _pendingExternalNotify;
      _pendingExternalNotify = false;

      // 🔧 repo says "events changed" → bust resolver cache for this group
      _resolver.clearGroup(_group.id);

      _scheduleRecompute(notifyExternal: notify);
    });
  }

  Future<void> _bootstrap(BuildContext context, List<Event> initial) async {
    if (initial.isNotEmpty) {
      for (final e in initial) {
        _repo.onSocketCreated(_group.id, e.toJson());
      }
    }

    await _repo.refreshGroup(_group.id);

    final current = await _repo.getEventsByGroupId(_group.id);
    await Future.wait(current.map((e) async {
      await _syncReminderSafely(context, e, operation: 'bootstrap');
    }));

    // first load → make sure cache is fresh
    _resolver.clearGroup(_group.id);
    _scheduleRecompute(notifyExternal: false);
  }

  int? _lastExpandedSig;

  // coalescing helper
  void _scheduleRecompute({required bool notifyExternal}) {
    _recomputeDebounce?.cancel();
    _recomputeDebounce = Timer(const Duration(milliseconds: 16), () {
      if (_disposed) return;
      _recomputeVisibleWindow(notifyExternal);
    });
  }

  int _computeSignature(List<Event> list) {
    final parts = list.map((e) => Object.hash(
          e.id,
          e.rawRuleId,
          e.startDate.millisecondsSinceEpoch,
          e.endDate.millisecondsSinceEpoch,
          e.title.hashCode,
          e.recurrenceRule?.hashCode ?? e.rule?.hashCode ?? 0,
          e.eventColorIndex,
          e.allDay ? 1 : 0,
        ));
    return Object.hashAllUnordered(parts);
  }

  Future<void> _recomputeVisibleWindow([bool notifyExternal = false]) async {
    if (_disposed) return;

    final t0 = DateTime.now();
    devtools
        .log('[EventDomain] ▸ recompute start notifyExternal=$notifyExternal');

    final now = DateTime.now();
    final range = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now.add(const Duration(days: 365)),
    );

    // 1) hydrated base events (via resolver + repo)
    final hydrated = await _resolver.getHydratedEventsForGroup(
      group: _group,
      fetchBaseEvents: _repo.getEventsByGroupId,
      useCache:
          true, // cache is safe because we manually clear it when things change
    );
    devtools.log('[EventDomain]   base(hydrated)=${hydrated.length}');

    // 2) expand + dedupe via resolver
    final visible = _resolver.expandForRange(
      baseEvents: hydrated,
      range: range,
      maxOccurrences: 1000,
    );

    // 3) signature check
    final sig = _computeSignature(visible);
    final changed = _lastExpandedSig != sig;

    devtools.log('[EventDomain]   visible=${visible.length} changed=$changed '
        'elapsed=${DateTime.now().difference(t0).inMilliseconds}ms');

    if (!changed) {
      devtools.log('[EventDomain] ◂ recompute NO-OP (same signature)');
      return;
    }
    _lastExpandedSig = sig;

    // 4) push to notifier
    eventsNotifier.value = visible;

    // 5) external notify (socket-originated)
    if (notifyExternal) {
      onExternalEventUpdate?.call();
    }

    devtools.log('[EventDomain] ◂ recompute done total=${visible.length}');
  }

  void _setupSocketForwarding() {
    final socket = SocketManager();

    socket.on(SocketEvents.created, (data) {
      if (_disposed) return;
      _repo.onSocketCreated(_group.id, data);
      _pendingExternalNotify = true;
      // repo.events$ listener will bust cache + recompute
    });
    socket.on(SocketEvents.updated, (data) {
      if (_disposed) return;
      _repo.onSocketUpdated(_group.id, data);
      _pendingExternalNotify = true;
    });
    socket.on(SocketEvents.deleted, (data) {
      if (_disposed) return;
      _repo.onSocketDeleted(_group.id, data);
      _pendingExternalNotify = true;
    });
  }

  Stream<List<Event>> watchEvents() => _repo.events$(_group.id);

  Future<void> manualRefresh(BuildContext context,
      {bool silent = false}) async {
    if (_isRefreshing) {
      devtools.log('↻ [EventDomain] manualRefresh already running — skip');
      return;
    }
    _isRefreshing = true;
    if (!silent) _setLoading(true);
    try {
      await _repo.refreshGroup(_group.id);

      // ðŸ”§ force fresh base events
      _resolver.clearGroup(_group.id);
      _scheduleRecompute(notifyExternal: false);
    } catch (e, st) {
      devtools.log('ðŸ’¥ [EventDomain] manualRefresh error: $e\n$st');
    } finally {
      if (!silent) _setLoading(false);
      _isRefreshing = false;
    }
  }

  Future<EventMutationResult> createEvent(
    BuildContext context,
    Event event,
  ) async {
    final created = await _repo.createEvent(event);
    final reminderUnavailable = !await _syncReminderSafely(
      context,
      created,
      operation: 'create',
      showSchedulingStatus: true,
    );

    // 🔧 local mutation → bust cache + recompute
    _resolver.clearGroup(_group.id);
    _scheduleRecompute(notifyExternal: false);

    return EventMutationResult(
      event: created,
      reminderUnavailable: reminderUnavailable,
    );
  }

  Future<EventMutationResult> updateEvent(
    BuildContext context,
    Event event,
  ) async {
    final updated = await _repo.updateEvent(event);
    final reminderUnavailable = !await _syncReminderSafely(
      context,
      updated,
      operation: 'update',
      showSchedulingStatus: true,
    );

    // 🔧 local mutation → bust cache + recompute
    _resolver.clearGroup(_group.id);
    _scheduleRecompute(notifyExternal: false);

    return EventMutationResult(
      event: updated,
      reminderUnavailable: reminderUnavailable,
    );
  }

  Future<void> deleteEvent(String id) async {
    final eventId = baseId(id);
    var eventsToCancel = <Event>[];
    try {
      eventsToCancel = (await _repo.getEventsByGroupId(_group.id))
          .where(
            (e) =>
                baseId(e.id) == eventId ||
                baseId(e.rawRuleId ?? '') == eventId,
          )
          .toList();
    } catch (error, stackTrace) {
      devtools.log(
        'local_reminder_failure operation=delete_lookup '
        'eventId=$eventId groupId=$_group.id',
        name: 'EventDomain',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _repo.deleteEvent(id);

    for (final e in eventsToCancel) {
      try {
        await _cancelReminder(e);
      } catch (error, stackTrace) {
        _logReminderFailure(
          operation: 'delete',
          event: e,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // 🔧 local mutation → bust cache + recompute
    _resolver.clearGroup(_group.id);
    _scheduleRecompute(notifyExternal: false);
  }

  Future<bool> _syncReminderSafely(
    BuildContext context,
    Event event, {
    required String operation,
    bool showSchedulingStatus = false,
  }) async {
    try {
      await _syncReminder(
        context,
        event,
        showSchedulingStatus: showSchedulingStatus,
      );
      return true;
    } catch (error, stackTrace) {
      _logReminderFailure(
        operation: operation,
        event: event,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void _logReminderFailure({
    required String operation,
    required Event event,
    required Object error,
    required StackTrace stackTrace,
  }) {
    devtools.log(
      'local_reminder_failure operation=$operation '
      'eventId=${event.id} groupId=${event.groupId}',
      name: 'EventDomain',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<Event?> fetchEvent(String id, {String? fallbackId}) async {
    try {
      return await _repo.getEventById(id);
    } catch (_) {
      if (fallbackId != null) return await _repo.getEventById(fallbackId);
      rethrow;
    }
  }

  void dispose() {
    _disposed = true;
    eventsNotifier.dispose();
    _repoSub?.cancel();
    _recomputeDebounce?.cancel();
    final socket = SocketManager();
    socket.off(SocketEvents.created);
    socket.off(SocketEvents.updated);
    socket.off(SocketEvents.deleted);
  }
}
