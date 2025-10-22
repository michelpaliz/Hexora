import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:hexora/c-frontend/d-event-section/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class EventCompactView extends StatelessWidget {
  final Event event;
  final CalendarAppointmentDetails details;
  final Color textColor;
  final EventActionManager? actionManager;
  final ColorManager colorManager;
  final String userRole;

  const EventCompactView({
    super.key,
    required this.event,
    required this.details,
    required this.textColor,
    required this.colorManager,
    required this.userRole,
    this.actionManager,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = colorManager.getColor(event.eventColorIndex);
    final canEditEvent = canEdit(userRole);

    return GestureDetector(
      onTap: () {
        if (canEditEvent) actionManager?.editEvent(event, context);
      },
      child: Container(
        width: details.bounds.width,
        height: details.bounds.height,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: cardColor),
          borderRadius: BorderRadius.circular(6),
          color: cardColor.withOpacity(0.1),
        ),
        child: Center(
          child: Text(
            event.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}
