import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class MiniMonthPicker extends StatelessWidget {
  const MiniMonthPicker({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.events,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<Event> events;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final monthLabel = _monthLabel(visibleMonth);
    final dayKeys = _eventDaysForMonth(visibleMonth, events);
    final days = _buildMonthGrid(visibleMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel,
                style: typo.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevMonth,
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _WeekdayHeader(),
        const SizedBox(height: 4),
        GridView.builder(
          itemCount: days.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            if (day == null) {
              return const SizedBox.shrink();
            }
            final isSelected = _isSameDay(day, selectedDate);
            final hasEvents = dayKeys.contains(_dayKey(day));
            final isToday = _isSameDay(day, DateTime.now());
            final fg = isSelected ? cs.onPrimary : cs.onSurface;
            final bg = isSelected ? cs.primary : Colors.transparent;
            final borderColor =
                isToday ? cs.primary : cs.outlineVariant.withOpacity(0.5);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onDaySelected(day),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: borderColor, width: isToday ? 1.4 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day.day}',
                      style: typo.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasEvents)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected ? cs.onPrimary : cs.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 7),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<DateTime?> _buildMonthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (first.weekday - DateTime.monday) % 7;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cells = rows * 7;

    return List<DateTime?>.generate(cells, (index) {
      final dayIndex = index - leading + 1;
      if (dayIndex < 1 || dayIndex > daysInMonth) return null;
      return DateTime(month.year, month.month, dayIndex);
    });
  }

  Set<int> _eventDaysForMonth(DateTime month, List<Event> events) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final keys = <int>{};

    for (final e in events) {
      final start =
          DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
      final endInstant = e.endDate.subtract(const Duration(microseconds: 1));
      final end = DateTime(endInstant.year, endInstant.month, endInstant.day);
      if (end.isBefore(first) || start.isAfter(last)) continue;

      var cursor = start.isBefore(first) ? first : start;
      final lastDay = end.isAfter(last) ? last : end;
      while (!cursor.isAfter(lastDay)) {
        keys.add(_dayKey(cursor));
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return keys;
  }

  int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: typo.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
