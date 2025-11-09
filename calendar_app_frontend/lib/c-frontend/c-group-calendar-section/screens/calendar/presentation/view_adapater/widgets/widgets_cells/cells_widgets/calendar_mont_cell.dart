import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/d-event-section/utils/color_manager.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

Widget buildMonthCell({
  required BuildContext context,
  required MonthCellDetails details,
  required DateTime? selectedDate,
  required List<Event> events,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final typo = AppTypography.of(context);

  // --- date helpers ---
  final date =
      DateTime(details.date.year, details.date.month, details.date.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final isSelected = selectedDate != null &&
      selectedDate.year == date.year &&
      selectedDate.month == date.month &&
      selectedDate.day == date.day;

  final isToday = date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  final isWeekend =
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  final isPast = date.isBefore(today);

  // --- events overlap this day ---
  final dayStart = date;
  final dayEnd = dayStart.add(const Duration(days: 1));
  final eventsForDay = events
      .where((e) => e.startDate.isBefore(dayEnd) && e.endDate.isAfter(dayStart))
      .toList();

  // --- palette (Material 3 flavored) ---
  final baseBg = Colors.transparent;
  final baseFg = (isPast ? typo.bodyMedium : typo.bodyLarge).color ??
      scheme.onSurface.withOpacity(isPast ? 0.55 : 0.87);

  final selectedBg = scheme.primaryContainer; // strong but soft
  final selectedFg = scheme.onPrimaryContainer;

  final weekendBg = scheme.secondaryContainer
      .withOpacity(isDark ? 0.18 : 0.26); // gentle weekend tint

  final todayRing = scheme.primary.withOpacity(0.90); // ring around “today”
  final todayFill = scheme.primary.withOpacity(isDark ? 0.08 : 0.10);

  // Busy overlay (very subtle tint if many events)
  final isBusy = eventsForDay.length >= 4;
  final busyTint = scheme.tertiary.withOpacity(isDark ? 0.10 : 0.08);

  // --- decide background ---
  Color bg = baseBg;
  if (isSelected) {
    bg = selectedBg;
  } else if (isToday) {
    bg = todayFill;
  } else if (isWeekend) {
    bg = weekendBg;
  }
  if (!isSelected && isBusy) {
    bg = Color.alphaBlend(busyTint, bg);
  }

  // --- text styles from AppTypography ---
  final countStyle = (isSelected
          ? typo.caption.copyWith(color: selectedFg)
          : typo.caption.copyWith(color: baseFg.withOpacity(0.70)))
      .copyWith(fontSize: 10, fontWeight: FontWeight.w400);

  final dayNumberStyle = (isSelected
          ? typo.displayMedium.copyWith(color: selectedFg)
          : typo.titleLarge.copyWith(color: baseFg))
      .copyWith(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600);

  return LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = constraints.maxHeight < 56;

      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: scheme.primary, width: 1)
              : Border.all(
                  color: scheme.outlineVariant.withOpacity(0.35), width: 0.6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Today ring (behind content)
            if (!isSelected && isToday)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: todayRing, width: 1.2),
                    ),
                  ),
                ),
              ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isCompact && eventsForDay.isNotEmpty)
                    Text(
                      '${eventsForDay.length} event${eventsForDay.length > 1 ? 's' : ''}',
                      style: countStyle,
                    ),
                  Text(
                    '${date.day}',
                    style: dayNumberStyle,
                  ),
                  if (eventsForDay.isNotEmpty)
                    SizedBox(
                      height: 12,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 3,
                        runSpacing: 2,
                        children: eventsForDay.take(4).map((event) {
                          final color = (event.eventColorIndex >= 0 &&
                                  event.eventColorIndex <
                                      ColorManager.eventColors.length)
                              ? ColorManager.eventColors[event.eventColorIndex]
                              : (isDark ? Colors.white70 : Colors.black38);
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 0.8, // keeps dots visible over tinted bg
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms, curve: Curves.easeInOut);
    },
  );
}
