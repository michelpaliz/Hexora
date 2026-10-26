import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/models/weather/day_summary.dart';
import 'package:hexora/presentation/screens/events/utils/color_manager.dart';
import 'package:hexora/presentation/shared/utils/weather/weather_summary_localizer.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

Widget buildMonthCell({
  required BuildContext context,
  required MonthCellDetails details,
  required DateTime? selectedDate,
  required List<Event> events,
  Map<DateTime, DaySummary>? weatherSummaries,
  ValueChanged<Event>? onEventTap,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final typo = AppTypography.of(context);
  final l = AppLocalizations.of(context)!;

  // --- date helpers ---
  final date =
      DateTime(details.date.year, details.date.month, details.date.day);
  final visibleMonthDate = details.visibleDates.isEmpty
      ? date
      : details.visibleDates[details.visibleDates.length ~/ 2];
  final isAdjacentMonth = date.month != visibleMonthDate.month ||
      date.year != visibleMonthDate.year;
  final normalizedForecast = weatherSummaries ?? const {};
  final weatherSummary = normalizedForecast[date];
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
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  // --- palette (Material 3 flavored) ---
  const baseBg = Colors.transparent;
  final baseFg = isAdjacentMonth
      ? scheme.onSurfaceVariant.withValues(alpha: 0.48)
      : ((isPast ? typo.bodyMedium : typo.bodyLarge).color ??
          scheme.onSurface.withValues(alpha: isPast ? 0.55 : 0.87));

  final selectedBg = scheme.primaryContainer; // strong but soft
  final selectedFg = scheme.onPrimaryContainer;

  final weekendBg = scheme.secondaryContainer
      .withValues(alpha: isDark ? 0.18 : 0.26); // gentle weekend tint

  final todayRing =
      scheme.primary.withValues(alpha: 0.90); // ring around “today”
  final todayFill = scheme.primary.withValues(alpha: isDark ? 0.08 : 0.10);

  // Busy overlay (very subtle tint if many events)
  final isBusy = eventsForDay.length >= 4;
  final busyTint = scheme.tertiary.withValues(alpha: isDark ? 0.10 : 0.08);

  // --- decide background ---
  Color bg = baseBg;
  if (isAdjacentMonth) {
    bg = scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.28 : 0.5);
  }
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

  String weatherTemperatureLabel(DaySummary summary) {
    final temp = summary.tempMax;
    if (temp == null) return '';
    return '${temp.round()}°';
  }

  Color weatherTemperatureColor(DaySummary summary) {
    if (summary.isTooHot) return const Color(0xFFDC2626);
    if (summary.isTooCold) return const Color(0xFF2563EB);
    return isSelected ? scheme.primary : const Color(0xFF64748B);
  }

  Color weatherChipBackground(DaySummary summary) {
    final accent = weatherTemperatureColor(summary);
    if (isSelected) {
      return scheme.surface.withValues(alpha: isDark ? 0.18 : 0.72);
    }
    return accent.withValues(alpha: isDark ? 0.18 : 0.10);
  }

  Color weatherChipBorder(DaySummary summary) {
    return weatherTemperatureColor(summary).withValues(
      alpha: isDark ? 0.30 : 0.18,
    );
  }

  // --- text styles from AppTypography ---
  final dayNumberStyle = (isSelected
          ? typo.displayMedium.copyWith(color: selectedFg)
          : typo.titleLarge.copyWith(color: baseFg))
      .copyWith(
    fontSize: 12,
    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
  );

  return LayoutBuilder(
    builder: (context, constraints) {
      if (MediaQuery.sizeOf(context).width < 700) {
        final weather = weatherSummary;
        final showWeather = weather != null &&
            constraints.maxHeight >=
                MediaQuery.textScalerOf(context).scale(18) + 26;
        return Tooltip(
          message: [
            if (weather != null) localizeWeatherSummary(l, weather.summary),
            if (weather != null) weatherTemperatureLabel(weather),
            if (eventsForDay.isNotEmpty)
              '${eventsForDay.length} ${l.sectionEvents}',
          ].join(' · '),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected || isToday
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${date.day}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected ? selectedFg : baseFg,
                      fontWeight: FontWeight.w700)),
              if (showWeather)
                Flexible(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                            '${weather.emoji} ${weatherTemperatureLabel(weather)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)))),
              if (eventsForDay.isNotEmpty)
                Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: scheme.primary, shape: BoxShape.circle)),
            ]),
          ),
        );
      }

      final isDenseHeight = constraints.maxHeight < 44;
      final maxVisibleEvents = constraints.maxHeight >= 92
          ? 3
          : constraints.maxHeight >= 68
              ? 2
              : constraints.maxHeight >= 50
                  ? 1
                  : 0;
      final visibleEvents = eventsForDay.take(maxVisibleEvents).toList();
      final hiddenEventCount = eventsForDay.length - visibleEvents.length;

      // Slightly smaller / tighter icon if the cell is really small
      final weatherFontSize = isDenseHeight ? 10.5 : 12.5;
      final tempFontSize = isDenseHeight ? 8.0 : 9.0;
      final dayFontSize = isDenseHeight ? 11.0 : 12.0;

      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: scheme.primary, width: 1)
              : Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                  width: 0.6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.22),
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

            // Main content (date + events)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${date.day}',
                    style: dayNumberStyle.copyWith(fontSize: dayFontSize),
                  ),
                  if (visibleEvents.isNotEmpty) const SizedBox(height: 3),
                  for (final event in visibleEvents) ...[
                    Builder(
                      builder: (context) {
                        final eventColor = event.eventColorIndex >= 0 &&
                                event.eventColorIndex <
                                    ColorManager.eventColors.length
                            ? ColorManager.eventColors[event.eventColorIndex]
                            : scheme.primary;
                        return Tooltip(
                          message: event.title,
                          child: InkWell(
                            onTap: onEventTap == null
                                ? null
                                : () => onEventTap(event),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: double.infinity,
                              height: 17,
                              margin: const EdgeInsets.only(bottom: 2),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: eventColor.withValues(
                                  alpha: isAdjacentMonth ? 0.08 : 0.14,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border(
                                  left: BorderSide(
                                    color: eventColor.withValues(
                                      alpha: isAdjacentMonth ? 0.45 : 0.9,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typo.caption.copyWith(
                                  fontSize: 9.5,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(
                                    alpha: isAdjacentMonth ? 0.5 : 0.86,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (hiddenEventCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 1),
                      child: Text(
                        '+$hiddenEventCount ${l.localeName.toLowerCase().startsWith('es') ? 'más' : 'more'}',
                        maxLines: 1,
                        style: typo.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary.withValues(
                            alpha: isAdjacentMonth ? 0.55 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tiny weather summary in top-right corner
            if (weatherSummary != null)
              Positioned(
                top: 4,
                right: 4,
                child: Tooltip(
                  message: [
                    localizeWeatherSummary(l, weatherSummary.summary),
                    if (weatherTemperatureLabel(weatherSummary).isNotEmpty)
                      weatherTemperatureLabel(weatherSummary),
                  ].join(' · '),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 17),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: weatherChipBackground(weatherSummary),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: weatherChipBorder(weatherSummary),
                        width: 0.7,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(
                        height: 1,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weatherSummary.emoji,
                            style: typo.titleLarge.copyWith(
                              fontSize: weatherFontSize,
                              height: 1,
                            ),
                          ),
                          if (weatherTemperatureLabel(weatherSummary)
                              .isNotEmpty) ...[
                            const SizedBox(width: 2.5),
                            Text(
                              weatherTemperatureLabel(weatherSummary),
                              style: typo.caption.copyWith(
                                color: weatherTemperatureColor(weatherSummary),
                                fontSize: tempFontSize,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                letterSpacing: -0.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms, curve: Curves.easeInOut);
    },
  );
}
