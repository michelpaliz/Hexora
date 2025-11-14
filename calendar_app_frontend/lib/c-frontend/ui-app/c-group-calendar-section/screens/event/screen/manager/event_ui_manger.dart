import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/bridge/event_display_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/widgets/event_content_builder.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// It bundles four things (`ColorManager`, `EventContentBuilder`, `EventActionManager`, `EventDisplayManager`) and **delegates** all UI building to `EventDisplayManager`, plus exposes the **add-event button** from `EventActionManager`. It doesn’t render anything itself—just forwards calls.

class EventUIManager {
  final ColorManager colorManager;
  final EventContentBuilder contentBuilder;
  final EventActionManager actionManager;
  final EventDisplayManager displayManager;

  EventUIManager({
    required this.colorManager,
    required this.contentBuilder,
    required this.actionManager,
    required this.displayManager,
  });

  /// Delegates to EventDisplayManager for full detail view
  Widget buildEventDetails(
    Event event,
    BuildContext context,
    Color textColor,
    dynamic appointment,
    String userRole,
  ) {
    return displayManager.buildEventDetails(
      event,
      context,
      textColor,
      appointment,
      userRole,
    );
  }

  /// Delegates to EventDisplayManager for future content view
  Widget buildFutureEventContent(
    Event event,
    Color textColor,
    CalendarAppointmentDetails details,
    String userRole,
  ) {
    return displayManager.buildFutureEventContent(
      event,
      textColor,
      details,
      userRole,
    );
  }

  /// Button builder — delegates to EventActionManager
  Widget buildAddEventButton(BuildContext context, Group group) {
    return actionManager.buildAddEventButton(context, group);
  }

  /// Compact view — day/week/agenda views
  Widget buildNonMonthViewEvent(
    Event event,
    CalendarAppointmentDetails details,
    Color textColor,
    String userRole,
  ) {
    return displayManager.buildNonMonthViewEvent(
      event,
      details,
      textColor,
      userRole,
    );
  }

  /// Timeline view box style
  Widget buildTimelineDayStrip(
    Event event,
    CalendarAppointmentDetails details,
    Color textColor,
    String userRole,
  ) {
    return displayManager.buildTimelineDayAppointment(
      event,
      details,
      textColor,
      userRole,
    );
  }

  /// Schedule view — card layout
  Widget buildScheduleCardView(
    Event event,
    BuildContext context,
    Color textColor,
    dynamic appointment,
    String userRole,
  ) {
    return displayManager.buildScheduleViewEvent(
      event,
      context,
      textColor,
      appointment,
      userRole,
    );
  }
}
