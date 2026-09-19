// lib/presentation/b-calendar-section/screens/agenda/widgets/agenda_header.dart
import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/agenda_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AgendaHeader extends StatelessWidget {
  final DateTime? selectedDay;
  final ValueChanged<DateTime?>? onSelectDay;
  final List<AgendaItem> items;
  final int daysRange;
  final VoidCallback onExpandRange;
  final VoidCallback onRefresh;
  final bool showGreeting;

  const AgendaHeader({
    super.key,
    this.selectedDay,
    this.onSelectDay,
    required this.items,
    required this.daysRange,
    required this.onExpandRange,
    required this.onRefresh,
    this.showGreeting = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final total = items.length;
    final done = items.where(_isDone).length;
    final donePct = total == 0 ? 0.0 : done / total;

    final buckets = _buildWeekBuckets(context, items);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(loc.completedSummary(done, total, (donePct * 100).round()),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: donePct,
            minHeight: 5,
            borderRadius: BorderRadius.circular(8)),
        const SizedBox(height: 8),
        Row(children: [
          _DayRangeToggle(
              daysRange: daysRange, onToggle: onExpandRange, loc: loc, cs: cs),
          const Spacer(),
          IconButton(
              tooltip: loc.refresh,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 8),
        _WeekStrip(
            buckets: buckets,
            selectedDay: selectedDay,
            onSelectDay: onSelectDay),
      ]),
    );
  }

  bool _isDone(AgendaItem it) {
    final e = it.event;
    if (e.isDone == true) return true;
    if (e.completedAt != null) return true;
    final s = (e.status ?? '').toLowerCase();
    return s == 'done' || s == 'completed' || s == 'finished';
  }

  List<_DayBucket> _buildWeekBuckets(
      BuildContext context, List<AgendaItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = today;
    final count = daysRange;
    final end = start.add(Duration(days: count - 1));

    final counts = List<int>.filled(count, 0);
    for (final it in items) {
      final local = it.event.startDate.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      final idx = day.difference(start).inDays;
      counts[idx] += 1;
    }

    return List<_DayBucket>.generate(count, (i) {
      final date = start.add(Duration(days: i));
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isPast = date.isBefore(today);
      return _DayBucket(
          date: date, count: counts[i], isToday: isToday, isPast: isPast);
    });
  }
}

// ── Day range segmented toggle ─────────────────────────────────────────────────

class _DayRangeToggle extends StatelessWidget {
  final int daysRange;
  final VoidCallback onToggle;
  final AppLocalizations loc;
  final ColorScheme cs;

  const _DayRangeToggle({
    required this.daysRange,
    required this.onToggle,
    required this.loc,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final is30 = daysRange >= 30;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: '14d',
            selected: !is30,
            onTap: is30 ? onToggle : null,
            cs: cs,
          ),
          _Segment(
            label: '30d',
            selected: is30,
            onTap: !is30 ? onToggle : null,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final ColorScheme cs;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected
                ? cs.onPrimary
                : cs.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

// ── Week strip ─────────────────────────────────────────────────────────────────

class _DayBucket {
  final DateTime date;
  final int count;
  final bool isToday;
  final bool isPast;
  const _DayBucket(
      {required this.date,
      required this.count,
      required this.isToday,
      required this.isPast});
}

class _WeekStrip extends StatelessWidget {
  final List<_DayBucket> buckets;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?>? onSelectDay;
  const _WeekStrip({required this.buckets, this.selectedDay, this.onSelectDay});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(AppLocalizations.of(context)!.all),
            selected: selectedDay == null,
            onSelected: onSelectDay == null ? null : (_) => onSelectDay!(null),
          ),
        ),
        for (final bucket in buckets)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              tooltip: DateFormat.yMMMMEEEEd(locale).format(bucket.date),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(DateFormat.E(locale).format(bucket.date).toUpperCase()),
                  Text('${bucket.date.day}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${bucket.count}',
                      style: Theme.of(context).textTheme.labelSmall),
                ]),
              ),
              selected: DateUtils.isSameDay(selectedDay, bucket.date),
              onSelected:
                  onSelectDay == null ? null : (_) => onSelectDay!(bucket.date),
            ),
          ),
      ]),
    );
  }
}
