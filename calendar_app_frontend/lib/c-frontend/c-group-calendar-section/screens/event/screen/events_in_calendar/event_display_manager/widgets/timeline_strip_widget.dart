import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:hexora/c-frontend/d-event-section/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Updated TimelineStripWidget that is optimized for:
// CalendarView.timelineDay
// CalendarView.timelineWeek
// (Optionally) CalendarView.timelineMonth
class TimelineStripWidget extends StatelessWidget {
  final Event event;
  final CalendarAppointmentDetails details;
  final Color textColor;
  final EventActionManager? actionManager;
  final ColorManager colorManager;
  final String userRole;

  const TimelineStripWidget({
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
    final bgColor = colorManager
        .getColor(event.eventColorIndex)
        .withOpacity(0.2);
    final borderColor = colorManager.getColor(event.eventColorIndex);
    final canEditEvent = canEdit(userRole);

    return GestureDetector(
      onTap: () {
        if (canEditEvent) {
          actionManager?.editEvent(event, context);
        }
      },
      onLongPress: () {
        // Optional: Quick preview or detail view
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              event.description ?? 'No description available',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      },
      child: Container(
        width: details.bounds.width,
        height: details.bounds.height,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      decoration: event.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.recurrenceRule != null)
                    Text(
                      '🔁 ${event.recurrenceDescription}',
                      style: TextStyle(
                        fontSize: 9, // Reduced
                        color: textColor.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
