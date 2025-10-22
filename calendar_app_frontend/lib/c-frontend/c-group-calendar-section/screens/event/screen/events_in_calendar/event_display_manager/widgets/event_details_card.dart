import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/leading_icon.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/widgets/event_date_time.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/screen/events_in_calendar/widgets/event_title_row.dart';
import 'package:hexora/c-frontend/d-event-section/utils/color_manager.dart';

class EventDetailsCard extends StatelessWidget {
  final Event event;
  final BuildContext contextRef;
  final Color textColor;
  final dynamic appointment;
  final String userRole;
  final EventActionManager? actionManager;
  final ColorManager colorManager; // ✅ new

  const EventDetailsCard({
    super.key,
    required this.event,
    required this.contextRef,
    required this.textColor,
    required this.appointment,
    required this.userRole,
    required this.actionManager,
    required this.colorManager, // ✅ new
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = colorManager.getColor(event.eventColorIndex);
    final canAdmin = canEdit(userRole);

    return Padding(
      padding: EdgeInsets.zero, // remove vertical padding entirely
      child: Dismissible(
        key: Key(appointment.id),
        direction:
            canAdmin ? DismissDirection.endToStart : DismissDirection.none,
        background: _buildDeleteBackground(),
        confirmDismiss: (_) async {
          if (!canAdmin || actionManager == null) return false;

          debugPrint('🗑️  [UI] User requested delete for event ${event.id}');

          final ok = await actionManager!.removeEvent(event, /*silent*/ true);

          debugPrint('✅  [UI] removeEvent returned: $ok');

          return ok;
        },
        child: Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
          ), // 🔽 slightly less side margin
          elevation: 0.5, // 🔽 softer elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // 🔽 smaller radius if you want tighter look
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // 🔽 smaller internal padding
            child: Row(
              children: [
                buildLeadingIcon(cardColor, event),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EventDateTimeRow(event: event, textColor: textColor),
                      EventTitleRow(
                        event: event,
                        textColor: textColor,
                        colorManager: colorManager,
                      ),
                      if (event.description?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Text(
                            event.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11, // 🔽 slightly smaller font
                              color: textColor.withOpacity(0.75),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero, // 🔽 removes default 8px padding
                  constraints:
                      const BoxConstraints(), // 🔽 shrinks icon size box
                  icon: Icon(
                    Icons.more_vert,
                    color: cardColor,
                    size: 20,
                  ), // 🔽 smaller icon
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
