// lib/c-frontend/c-group-calendar-section/screens/calendar/calendar_screen_controller.dart
import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/event/socket/socket_manager.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/coordinator/app_screen_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/icapability/supports_view_mode.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/adapter_flow/adapter/calendar_view_adapter.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/bridge/event_display_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/widgets/event_content_builder.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/screen/add_event_screen.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:provider/provider.dart';

class CalendarScreenCoordinator {
  final BuildContext context;

  // Public loading state for the widget to listen to
  final ValueNotifier<bool> loading = ValueNotifier<bool>(true);
  bool get isLoading => loading.value;
  void _setLoading(bool v) => loading.value = v;

  String _currentViewMode = 'week';
  String get currentViewMode => _currentViewMode;

  // UI helpers
  final AppScreenManager _screenManager = AppScreenManager();

  // Presence
  late final PresenceDomain _presenceManager;

  // Calendar wiring
  CalendarViewAdapter? calendarUI;
  late final EventDisplayManager _displayManager;
  EventActionManager? _eventActionManager;

  // Keep track of last bound EventDomain & role to avoid unnecessary rebuilds
  EventDomain? _lastEventDomain;
  String? _lastUserRole;

  bool _socketsInitialized = false;

  CalendarScreenCoordinator({required this.context}) {
    _initDisplayManager();
  }

  void _initDisplayManager() {
    final colorManager = ColorManager();
    final contentBuilder = EventContentBuilder(colorManager: colorManager);
    _displayManager = EventDisplayManager(null, builder: contentBuilder);
  }

  void jumpToToday() {
    calendarUI?.jumpToToday();
  }

// calendar_screen_controller.dart

  void setViewMode(String mode) {
    _currentViewMode = mode;

    final ui = calendarUI;
    if (ui == null) {
      devtools.log('[Calendar] setViewMode before init (mode=$mode)');
      return;
    }
    (ui as SupportsViewMode).setViewMode(mode);
    devtools.log('[Calendar] View mode -> $mode');
  }

  Future<void> initSockets() async {
    if (_socketsInitialized) return;
    _socketsInitialized = true;

    _presenceManager = context.read<PresenceDomain>();
    final token = await context.read<AuthService>().getToken();
    if (token != null) {
      final socket = SocketManager();
      socket.connect(token);
      socket.on('presence:update', (data) {
        _presenceManager.updatePresenceList(data);
      });
    } else {
      devtools.log("⚠️ No auth token — sockets not connected.");
    }
  }

  /// Initialize calendar view, group context, and events
  Future<void> loadData({Group? initialGroup}) async {
    final groupDomain = context.read<GroupDomain>();
    final userDomain = context.read<UserDomain>();
    final notifMgmt = context.read<NotificationDomain>();
    final eventDomain = context.read<EventDomain>();

    try {
      _setLoading(true);

      // 1) Set or confirm current group
      if (initialGroup != null) {
        groupDomain.currentGroup = initialGroup;
      } else if (groupDomain.currentGroup == null) {
        devtools.log("⚠️ No group provided and no currentGroup in manager.");
        _setLoading(false);
        return;
      }

      // 2) Refresh group from API (via repository)
      final updatedGroup = await groupDomain.groupRepository
          .getGroupById(groupDomain.currentGroup!.id);
      groupDomain.currentGroup = updatedGroup;

      // 3) Presence join emit
      final me = userDomain.user;
      if (me != null) {
        SocketManager().emitUserJoin(
          userId: me.id,
          userName: me.userName,
          groupId: updatedGroup.id,
          photoUrl: me.photoUrl,
        );
      }

      // 4) Load known users for presence
      final allUsers = await userDomain.getUsersForGroup(updatedGroup);
      _presenceManager.setKnownUsers(allUsers);

      // 5) Determine role
      final userRole = updatedGroup.userRoles[me?.id] ?? 'member';

      // 6) Initialize (or reuse) calendar + display + actions
      if (calendarUI == null) {
        calendarUI = CalendarViewAdapter(
          eventDomain: eventDomain,
          eventDisplayManager: _displayManager,
          userRole: userRole,
          groupDomain: groupDomain,
        );

        _eventActionManager = EventActionManager(
          groupDomain,
          userDomain,
          notifMgmt,
          eventDomain: eventDomain,
        );
        _displayManager.setEventActionManager(_eventActionManager!);

        _lastEventDomain = eventDomain;
        _lastUserRole = userRole;
      } else {
        // a) Rebind if Provider gave us a different EventDomain instance
        if (!identical(_lastEventDomain, eventDomain)) {
          calendarUI!.rebindEventDomain(eventDomain);
          _lastEventDomain = eventDomain;
        }
        // b) If the role changed, recreate controller (no updateUserRole API)
        if (_lastUserRole != userRole) {
          calendarUI!.dispose();
          calendarUI = CalendarViewAdapter(
            eventDomain: eventDomain,
            eventDisplayManager: _displayManager,
            userRole: userRole,
            groupDomain: groupDomain,
          );
          _lastUserRole = userRole;
        }
      }

      // 7) Single, idempotent refresh (silent to avoid UX flicker)
      await eventDomain.manualRefresh(context, silent: true);
      // UI redraw is driven by CalendarUIController's notifier listener.
    } catch (e, s) {
      devtools.log("❌ Error initializing calendar: $e\n$s");
    } finally {
      _setLoading(false);
    }
  }

  /// Handle new event creation flow
  Future<void> handleAddEventPressed(BuildContext context, Group group) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEventScreen(group: group)),
    );

    if (added == true) {
      // No full rebuild — just ask domain to refresh silently
      _setLoading(true);
      try {
        await context.read<EventDomain>().manualRefresh(context, silent: true);
      } finally {
        _setLoading(false);
      }
    }
  }

  /// Presence consumer for widget
  List<UserPresence> buildPresenceFor(Group group) {
    final roleMap = {...group.userRoles};
    return _presenceManager.getPresenceForGroup(group.userIds, roleMap);
  }

  void setScreenMetrics(BuildContext context) =>
      _screenManager.setScreenWidthAndCalendarHeight(context);

  void dispose() {
    SocketManager().off('presence:update');
    calendarUI?.dispose();
  }
}
