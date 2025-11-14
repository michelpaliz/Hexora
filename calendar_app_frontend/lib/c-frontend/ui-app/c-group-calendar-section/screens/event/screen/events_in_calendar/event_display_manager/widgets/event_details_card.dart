import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/leading_icon.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/widgets/event_date_time.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/widgets/event_title_row.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class EventDetailsCard extends StatelessWidget {
  final Event event;
  final BuildContext contextRef;
  final Color textColor;
  final dynamic appointment;
  final String userRole;
  final EventActionManager? actionManager;
  final ColorManager colorManager;

  const EventDetailsCard({
    super.key,
    required this.event,
    required this.contextRef,
    required this.textColor,
    required this.appointment,
    required this.userRole,
    required this.actionManager,
    required this.colorManager,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final cardAccent = colorManager.getColor(event.eventColorIndex);
    final canAdmin = canEdit(userRole);

    return Padding(
      padding: EdgeInsets.zero,
      child: Dismissible(
        key: Key(appointment.id),
        direction:
            canAdmin ? DismissDirection.endToStart : DismissDirection.none,
        background: _buildDeleteBackground(),
        confirmDismiss: (_) async {
          if (!canAdmin || actionManager == null) return false;
          final ok = await actionManager!.removeEvent(event, /*silent*/ true);
          return ok;
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                buildLeadingIcon(cardAccent, event),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Uses its own widget; ensure that widget also reads AppTypography internally
                      EventDateTimeRow(
                        event: event,
                        textColor: textColor,
                        // If you update that widget: use typo.bodySmall.copyWith(...)
                      ),
                      // Title row widget (ensure it uses typo.bodyMedium)
                      EventTitleRow(
                        event: event,
                        textColor: textColor,
                        colorManager: colorManager,
                      ),
                      // if ((event.description ?? '').isNotEmpty)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 2),
                      //     child: Text(
                      //       event.description!,
                      //       maxLines: 2,
                      //       overflow: TextOverflow.ellipsis,
                      //       style: typo.bodySmall.copyWith(
                      //         color: textColor.withOpacity(0.75),
                      //         letterSpacing: .1,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.more_vert,
                    color: cs.onSurfaceVariant, // subtle, consistent with UI
                    size: 20,
                  ),
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
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() => Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white, size: 20),
      );
}
