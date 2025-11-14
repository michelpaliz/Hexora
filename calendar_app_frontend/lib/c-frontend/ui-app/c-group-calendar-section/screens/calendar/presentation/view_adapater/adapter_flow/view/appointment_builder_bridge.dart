// appointment_builder_bridge.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widget_appointment/appointment_builder.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/bridge/event_display_manager.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

class AppointmentBuilderBridge {
  final CalendarAppointmentBuild builder;
  final String userRole;

  AppointmentBuilderBridge({
    required EventDisplayManager displayManager,
    required this.userRole,
  }) : builder = CalendarAppointmentBuild(displayManager);

  Widget build(
    BuildContext context,
    sf.CalendarView selectedView,
    sf.CalendarAppointmentDetails details,
    Color textColor,
  ) {
    final appt = details.appointments.first;
    if (appt is! Event) {
      return const Text('Invalid Event', style: TextStyle(color: Colors.red));
    }

    final event = appt;
    final cardColor = ColorManager().getColor(event.eventColorIndex);

    switch (selectedView) {
      case sf.CalendarView.schedule:
        return builder.buildScheduleAppointment(
          details,
          textColor,
          context,
          event,
          userRole,
          cardColor,
        );

      case sf.CalendarView.week:
      case sf.CalendarView.workWeek:
      case sf.CalendarView.day:
        return builder.buildWeekAppointment(
          details,
          textColor,
          event,
          userRole,
        );

      case sf.CalendarView.timelineDay:
        return builder.buildTimelineDayAppointment(
          details,
          textColor,
          event,
          userRole,
        );

      case sf.CalendarView.timelineWeek:
        return builder.buildTimelineWeekAppointment(
          details,
          textColor,
          event,
          userRole,
        );

      case sf.CalendarView.timelineMonth:
        return builder.buildTimelineMonthAppointment(
          details,
          textColor,
          event,
          userRole,
        );

      default:
        return builder.defaultBuildAppointment(
          details,
          textColor,
          context,
          selectedView.toString(),
          userRole,
        );
    }
  }
}
