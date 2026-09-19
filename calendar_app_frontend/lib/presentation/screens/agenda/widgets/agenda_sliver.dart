import 'package:hexora/presentation/routes/app_routes.dart';
// lib/presentation/b-calendar-section/screens/agenda/widgets/agenda_list_sliver.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hexora/models/calendar/agenda_model.dart';
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
  final VoidCallback? onTap;
  const AgendaTile({super.key, required this.item, this.onTap});

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
    final multiDay = !_sameDay(start, end) && !e.allDay;

    final timeStr = _formatTimeRange(context, start, e.allDay ? null : end);
    final durationStr = e.allDay
        ? null
        : _formatDuration(
            end.difference(start),
            Localizations.localeOf(context).toLanguageTag(),
          );
    final location = (e.localization ?? '').trim();

    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ??
              () => Navigator.pushNamed(context, AppRoutes.eventDetail,
                  arguments: e),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    isDone ? Icons.check_circle_outline : _icon(multiDay),
                    size: 20,
                    color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                        [timeStr, if (durationStr != null) durationStr]
                            .join(' · '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    if (location.isNotEmpty)
                      Text(location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    if (isDone) ...[
                      const SizedBox(height: 6),
                      Text('✓ ${l.agendaCompleted}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700)),
                    ],
                  ])),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
            ]),
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
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
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
