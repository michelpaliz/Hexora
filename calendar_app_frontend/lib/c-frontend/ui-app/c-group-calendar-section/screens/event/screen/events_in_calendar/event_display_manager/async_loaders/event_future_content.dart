// lib/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/async_loaders/event_future_content.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../widgets/event_details_card.dart';

class EventFutureContentWidget extends StatelessWidget {
  final Event event;
  final Color textColor;
  final CalendarAppointmentDetails details;
  final String userRole;
  final EventActionManager? actionManager;
  final ColorManager colorManager;

  // ✅ NEW: resolvers (id → name)

  const EventFutureContentWidget({
    super.key,
    required this.event,
    required this.textColor,
    required this.details,
    required this.userRole,
    required this.actionManager,
    required this.colorManager,
  });

  @override
  Widget build(BuildContext context) {
    if (actionManager == null) return const SizedBox.shrink();

    return SizedBox(
      width: details.bounds.width,
      height: details.bounds.height,
      child: FutureBuilder<Event?>(
        future: actionManager!.eventDomain.fetchEvent(event.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData && snapshot.data != null) {
            return EventDetailsCard(
              event: snapshot.data!,
              contextRef: context,
              textColor: textColor,
              appointment: details.appointments.first,
              userRole: userRole,
              actionManager: actionManager,
              colorManager: colorManager
            );
          } else {
            return Text(
              'No event found',
              style: TextStyle(fontSize: 14, color: textColor),
            );
          }
        },
      ),
    );
  }
}
