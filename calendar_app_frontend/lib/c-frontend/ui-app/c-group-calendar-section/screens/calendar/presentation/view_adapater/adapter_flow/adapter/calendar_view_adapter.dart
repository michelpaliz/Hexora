// lib/c-frontend/c-group-calendar-section/screens/calendar/presentation/view_adapater/adapter_flow/adapter/calendar_view_adapter.dart
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/icapability/supports_view_mode.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/adapter_flow/view/calendar_surface.dart'
    as widgets;
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/bridge/event_display_manager.dart';

import 'calendar_binding.dart';
import 'calendar_state.dart';
import '../view/appointment_builder_bridge.dart';

class CalendarViewAdapter implements SupportsViewMode {
  final GroupDomain groupDomain;
  final String userRole;
  final EventDisplayManager _displayManager;

  late final CalendarState _state;
  late final CalendarBinding _binding;
  late final AppointmentBuilderBridge _bridge;

  CalendarViewAdapter({
    required EventDomain eventDomain,
    required EventDisplayManager eventDisplayManager,
    required this.groupDomain,
    required this.userRole,
  }) : _displayManager = eventDisplayManager {
    _state = CalendarState();
    _binding = CalendarBinding(eventDomain, _state);
    _bridge = AppointmentBuilderBridge(
      displayManager: _displayManager,
      userRole: userRole,
    );
  }

  // ---- Public controls ------------------------------------------------------

  void jumpToToday() {
    _state.jumpToToday();
  }

  void rebindEventDomain(EventDomain newDomain) {
    _binding.rebind(newDomain);
  }

  @override
  void setViewMode(String mode) {
    // Delegate to CalendarState (expected to notify listeners & rebuild)
    _state.setViewMode(mode);
  }

  @override
  String get currentViewMode => _state.currentViewMode;

  // ---- UI -------------------------------------------------------------------

  Widget buildCalendar(BuildContext context, {double? height, double? width}) {
    return SizedBox(
      height: height,
      width: width,
      child: widgets.CalendarSurface(
        state: _state,
        apptBridge: _bridge,
      ),
    );
  }

  void dispose() {
    _binding.dispose();
    _state.dispose();
  }
}
