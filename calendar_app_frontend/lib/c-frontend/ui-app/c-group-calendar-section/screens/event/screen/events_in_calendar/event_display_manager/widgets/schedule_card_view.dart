import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/widgets/leading_icon.dart';
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

  /// Returns only the part after the first dash ( -, – or — ).
  /// If there's no dash, returns the original trimmed title.
  String clientOnlyTitle(String title) {
    final match = RegExp(r'\s*[-–—]\s*').firstMatch(title);
    if (match == null) return title.trim();
    return title.substring(match.end).trim();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Try to fetch a translated "All day" label from your localization keys.
  String _allDayLabel(AppLocalizationsMethods loc) {
    try {
      final dyn = loc as dynamic;
      final candidate =
          dyn.allDay ?? dyn.all_day ?? dyn.labelAllDay ?? dyn.label_all_day;
      if (candidate is String && candidate.trim().isNotEmpty) return candidate;
    } catch (_) {}
    return 'All day'; // fallback only if not provided by l10n
  }

  /// Compact, localization-first summary using only your `loc` formatters.
  /// Examples:
  ///  - <loc.formatDate(start)> • <HH:mm–HH:mm>
  ///  - <loc.formatDate(start)> • All day
  ///  - <loc.formatDate(start)>, <HH:mm> → <loc.formatDate(end)>, <HH:mm>
  ///  - <loc.formatDate(start)> → <loc.formatDate(end)> • All day
  String _compactEventTime({
    required DateTime start,
    required DateTime end,
    required bool allDay,
    required AppLocalizationsMethods loc,
  }) {
    final s = start.toLocal();
    final e = end.toLocal();

    if (allDay) {
      if (_isSameDay(s, e)) {
        return '${loc.formatDate(s)} • ${_allDayLabel(loc)}';
      }
      return '${loc.formatDate(s)} → ${loc.formatDate(e)} • ${_allDayLabel(loc)}';
    } else {
      if (_isSameDay(s, e)) {
        return '${loc.formatDate(s)} • ${loc.formatHours(s)}–${loc.formatHours(e)}';
      }
      return '${loc.formatDate(s)}, ${loc.formatHours(s)} → ${loc.formatDate(e)}, ${loc.formatHours(e)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizationsMethods.of(context)!;

    final startLocal = event.startDate.toLocal();
    final endLocal = event.endDate.toLocal();

    final dateLine = _compactEventTime(
      start: startLocal,
      end: endLocal,
      allDay: event.allDay,
      loc: loc,
    );

    final canAdmin = canEdit(userRole);

    // Typography: use your app's font via theme.textTheme body styles.
    final dateStyle = theme.textTheme.bodySmall?.copyWith(
      color: textColor.withOpacity(0.75),
      fontWeight: FontWeight.w500,
    );

    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      decoration: event.isDone ? TextDecoration.lineThrough : null,
      color: textColor,
    );

    final descStyle = theme.textTheme.bodySmall?.copyWith(
      color: textColor.withOpacity(0.7),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            buildLeadingIcon(cardColor, event, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact date line with icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.allDay ? Icons.event : Icons.schedule,
                        size: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          dateLine,
                          style: dateStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Title shows only the client name (after the dash)
                  Text(
                    clientOnlyTitle(event.title),
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.description?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: descStyle,
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
