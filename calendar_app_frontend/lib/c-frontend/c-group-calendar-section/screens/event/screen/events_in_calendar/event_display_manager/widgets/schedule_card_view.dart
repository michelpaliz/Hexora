import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/leading_icon.dart';
import 'package:hexora/l10n/AppLocalitationMethod.dart';

class ScheduleCardView extends StatelessWidget {
  final Event event;
  final BuildContext contextRef;
  final Color textColor;
  final dynamic appointment;
  final Color cardColor;
  final EventActionManager? actionManager;
  final String userRole;

  const ScheduleCardView({
    super.key,
    required this.event,
    required this.contextRef,
    required this.textColor,
    required this.appointment,
    required this.cardColor,
    required this.actionManager,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizationsMethods.of(context)!;

    // ✅ Convert to local time
    final startLocal = event.startDate.toLocal();
    final endLocal = event.endDate.toLocal();

    final formattedStartDate =
        '${loc.formatDate(startLocal)} (${loc.formatHours(startLocal)})';
    final formattedEndDate =
        '${loc.formatDate(endLocal)} (${loc.formatHours(endLocal)})';

    final dateTimeText = event.allDay
        ? '${loc.formatDate(startLocal)} (All Day)'
        : '$formattedStartDate  /  $formattedEndDate';

    final canAdmin = canEdit(userRole);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            buildLeadingIcon(cardColor, event, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateTimeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(event.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration:
                            event.isDone ? TextDecoration.lineThrough : null,
                        color: textColor,
                      )),
                  if (event.description?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: cardColor),
              onPressed: () {
                showEventActionsSheet(
                  context: context,
                  event: event,
                  canEdit: canAdmin,
                  actionManager: actionManager,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
