// lib/c-frontend/b-calendar-section/screens/calendar/event_screen_logic/ui/events_in_calendar/event_display_manager/event_display_manager.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/async_loaders/event_future_content.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/event_compact_view.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/event_details_card.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/schedule_card_view.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/timeline_strip_widget.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/widgets/event_content_builder.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Knows how to build the different event widgets (details card, compact strip,
/// timeline strip, schedule card, async future content). Optionally holds an
/// `EventActionManager` and always needs an `EventContentBuilder`.
class EventDisplayManager {
  EventActionManager? _actionManager;
  final EventContentBuilder _builder;

  // ✅ NEW: keep resolvers so all widgets can show names instead of IDs

  EventDisplayManager(
    EventActionManager? actionMgr, {
    required EventContentBuilder builder,
  })  : _actionManager = actionMgr,
        _builder = builder;

  void setEventActionManager(EventActionManager mgr) {
    _actionManager = mgr;
  }

  /// Full details card (used in non-month detailed panes).
  Widget buildEventDetails(
    Event event,
    BuildContext context,
    Color textColor,
    dynamic appointment,
    String userRole,
  ) {
    return EventDetailsCard(
      event: event,
      contextRef: context,
      textColor: textColor,
      appointment: appointment,
      userRole: userRole,
      actionManager: _actionManager,
      colorManager: _builder.colorManager,
    );
  }

  /// Async loader when the appointment needs to fetch extra data.
  Widget buildFutureEventContent(
    Event event,
    Color textColor,
    CalendarAppointmentDetails details,
    String userRole,
  ) {
    return EventFutureContentWidget(
      event: event,
      textColor: textColor,
      details: details,
      userRole: userRole,
      actionManager: _actionManager,
      colorManager: _builder.colorManager,
    );
  }

  /// Compact strip for day/week/agenda (non-month views).
  Widget buildNonMonthViewEvent(
    Event event,
    CalendarAppointmentDetails details,
    Color textColor,
    String userRole,
  ) {
    return EventCompactView(
      event: event,
      details: details,
      textColor: textColor,
      actionManager: _actionManager,
      colorManager: _builder.colorManager,
      userRole: userRole,
      // If your compact view also opens the action sheet,
      // add resolver fields there too (similar to EventDetailsCard).
    );
  }

  /// Timeline-day compact label.
  Widget buildTimelineDayAppointment(
    Event event,
    CalendarAppointmentDetails details,
    Color textColor,
    String userRole,
  ) {
    return TimelineStripWidget(
      event: event,
      details: details,
      textColor: textColor,
      actionManager: _actionManager,
      colorManager: _builder.colorManager,
      userRole: userRole,
      // Same note as above if it triggers the sheet.
    );
  }

  /// Schedule view card (and timeline-day detailed card).
  Widget buildScheduleViewEvent(
    Event event,
    BuildContext context,
    Color textColor,
    dynamic appointment,
    String userRole,
  ) {
    final cardColor = _builder.colorManager.getColor(event.eventColorIndex);
    return ScheduleCardView(
      event: event,
      contextRef: context,
      textColor: textColor,
      appointment: appointment,
      cardColor: cardColor,
      actionManager: _actionManager,
      userRole: userRole,
    );
  }
}
