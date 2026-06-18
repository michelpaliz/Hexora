// lib/c-frontend/b-calendar-section/screens/agenda/widgets/agenda_list_sliver.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hexora/a-models/group_model/agenda/agenda_model.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AgendaListSliver extends StatelessWidget {
  final List<AgendaItem> items;
  const AgendaListSliver({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.separated(
      itemBuilder: (_, i) {
        final curr = items[i];
        final showHeader = (i == 0) ||
            !_sameDay(items[i - 1].event.startDate, curr.event.startDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader) _DateHeader(date: curr.event.startDate),
            AgendaTile(item: curr),
          ],
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemCount: items.length,
    );
  }
}

// ── Event tile ─────────────────────────────────────────────────────────────────

class AgendaTile extends StatelessWidget {
  final AgendaItem item;
  const AgendaTile({super.key, required this.item});

  bool get _isDone {
    final e = item.event;
    if (e.isDone == true) return true;
    if (e.completedAt != null) return true;
    final s = (e.status ?? '').toLowerCase();
    return s == 'done' || s == 'completed' || s == 'finished';
  }

  IconData _icon(bool multiDay) {
    if (item.event.allDay) return Icons.event_rounded;
    if (multiDay) return Icons.date_range_rounded;
    final type = item.event.type.toLowerCase();
    if (type.contains('work')) return Icons.build_circle_outlined;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = item.event;
    final start = e.startDate.toLocal();
    final end = e.endDate.toLocal();
    final isDone = _isDone;
    final color = item.color;
    final multiDay = !_sameDay(start, end) && !e.allDay;

    final timeStr = _formatTimeRange(context, start, e.allDay ? null : end);
    final durationStr = e.allDay
        ? null
        : _formatDuration(
            end.difference(start),
            Localizations.localeOf(context).toLanguageTag(),
          );
    final location = (e.localization ?? '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: deep-link to event or group calendar
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDone
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.14)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.26),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.13),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left stripe ─────────────────────────────────────
                    Container(
                      width: 4,
                      color:
                          isDone ? color.withValues(alpha: 0.4) : color,
                    ),

                    // ── Icon box ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(
                              alpha: isDone ? 0.07 : 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isDone
                            ? Icon(Icons.check_rounded,
                                size: 18,
                                color: color.withValues(alpha: 0.55))
                            : Icon(_icon(multiDay),
                                size: 18, color: color),
                      ),
                    ),

                    // ── Content ──────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              e.title,
                              style: TextStyle(
                                fontSize: 13,
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
                            const SizedBox(height: 4),
                            // Time + optional location
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 10,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11,
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant
                                            .withValues(alpha: 0.65),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ] else if (item.groupName != null) ...[
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
                                      item.groupName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
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

                    // ── Duration badge ───────────────────────────────────
                    if (durationStr != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 11, horizontal: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(
                                alpha: isDone ? 0.06 : 0.11),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: color.withValues(
                                  alpha: isDone ? 0.18 : 0.32),
                            ),
                          ),
                          child: Text(
                            durationStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color.withValues(
                                  alpha: isDone ? 0.45 : 1.0),
                              letterSpacing: 0.1,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Date header ────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dLocal = date.toLocal();
    final now = DateTime.now();
    final isToday = _sameDay(dLocal, now);
    final isTomorrow = _sameDay(dLocal, now.add(const Duration(days: 1)));

    final label = isToday
        ? (loc?.today ?? 'Today')
        : isTomorrow
            ? (loc?.tomorrow ?? 'Tomorrow')
            : DateFormat.MMMEd(locale).format(dLocal);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        children: [
          if (isToday)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            )
          else if (isTomorrow)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) {
  final al = a.toLocal();
  final bl = b.toLocal();
  return al.year == bl.year && al.month == bl.month && al.day == bl.day;
}

String _formatTimeRange(BuildContext context, DateTime start, DateTime? end) {
  final ml = MaterialLocalizations.of(context);
  final s = ml.formatTimeOfDay(
    TimeOfDay.fromDateTime(start),
    alwaysUse24HourFormat: true,
  );
  if (end == null) return s;
  final e = ml.formatTimeOfDay(
    TimeOfDay.fromDateTime(end),
    alwaysUse24HourFormat: true,
  );
  return '$s – $e';
}

String _formatDuration(Duration duration, String locale) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes <= 0) return '0m';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}
