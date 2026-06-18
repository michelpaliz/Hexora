import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:intl/intl.dart';

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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTime(DateTime dt, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Hm(locale).format(dt);
  }

  String _timeRange(BuildContext context) {
    final s = event.startDate.toLocal();
    final e = event.endDate.toLocal();
    if (event.allDay) return _isSpanish(context) ? 'Todo el día' : 'All day';
    return '${_formatTime(s, context)} – ${_formatTime(e, context)}';
  }

  String _durationLabel(BuildContext context) {
    if (event.allDay) return '';
    final diff = event.endDate.difference(event.startDate);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'es';

  IconData _iconFor(bool multiDay) {
    if (event.allDay) return Icons.event_rounded;
    if (multiDay) return Icons.date_range_rounded;
    final type = event.type.toLowerCase();
    if (type.contains('work')) return Icons.build_circle_outlined;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final canAdmin = canEdit(userRole);

    final s = event.startDate.toLocal();
    final e = event.endDate.toLocal();
    final multiDay = !_isSameDay(s, e) && !event.allDay;

    final timeLabel = _timeRange(context);
    final durLabel = _durationLabel(context);
    final location = (event.localization ?? '').trim();
    final isDone = event.isDone;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isWide
                ? () => actionManager?.editEvent(event, context)
                : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDone
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.14)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.26),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.13),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left stripe ───────────────────────────────────────
                  Container(
                    width: 4,
                    color: isDone
                        ? cardColor.withValues(alpha: 0.4)
                        : cardColor,
                  ),

                  // ── Icon box ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cardColor.withValues(
                            alpha: isDone ? 0.07 : 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isDone
                          ? Icon(Icons.check_rounded,
                              size: 16,
                              color: cardColor.withValues(alpha: 0.55))
                          : Icon(_iconFor(multiDay),
                              size: 16, color: cardColor),
                    ),
                  ),

                  // ── Content ───────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDone
                                  ? cs.onSurface.withValues(alpha: 0.42)
                                  : cs.onSurface,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor:
                                  cs.onSurface.withValues(alpha: 0.42),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          // Time row
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 11,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                timeLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                  height: 1.2,
                                ),
                              ),
                              if (location.isNotEmpty) ...[
                                Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.65),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Duration badge ────────────────────────────────────
                  if (durLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(
                              alpha: isDone ? 0.06 : 0.11),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: cardColor.withValues(
                                alpha: isDone ? 0.18 : 0.32),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timelapse_rounded,
                              size: 12,
                              color: cardColor.withValues(
                                  alpha: isDone ? 0.45 : 1.0),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              durLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: cardColor.withValues(
                                    alpha: isDone ? 0.45 : 1.0),
                                letterSpacing: 0.1,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Chevron (desktop) / 3-dot (mobile) ────────────────
                  if (isWide)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.more_vert,
                          color: cardColor.withValues(alpha: 0.75), size: 17),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => showEventActionsSheet(
                        context: context,
                        event: event,
                        canEdit: canAdmin,
                        actionManager: actionManager,
                      ),
                    ),
                ],
              ), // Row
            ), // DecoratedBox
          ), // InkWell
        ), // Material
      ), // ClipRRect
    ); // Padding
  }
}
