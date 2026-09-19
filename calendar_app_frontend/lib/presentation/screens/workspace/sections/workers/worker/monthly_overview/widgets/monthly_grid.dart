import 'package:flutter/material.dart';

import 'month_tile_content.dart';

class MonthGrid extends StatelessWidget {
  final int year;
  final int? selectedMonth;
  final Map<int, Map<String, dynamic>> monthlyTotals;
  final void Function(int month) onTapMonth;
  final String Function(int month) monthNameBuilder;
  final String Function(Map<String, dynamic>? totals) subtitleBuilder;

  const MonthGrid({
    super.key,
    required this.year,
    required this.monthlyTotals,
    required this.onTapMonth,
    required this.monthNameBuilder,
    required this.subtitleBuilder,
    this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final availableWidth = constraints.maxWidth - 32;
      final columns = (availableWidth / (300 * textScale)).floor().clamp(1, 4);
      final tileWidth = (availableWidth - (columns - 1) * 12) / columns;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(12, (index) {
            final month = index + 1;
            final isCurrentMonth = now.year == year && now.month == month;
            final isSelected = selectedMonth == month;
            final totals = monthlyTotals[month];
            final metrics = MonthTotalMetrics.from(totals);
            final borderColor = isSelected
                ? scheme.primary.withValues(alpha: 0.42)
                : isCurrentMonth
                    ? scheme.primary.withValues(alpha: 0.24)
                    : scheme.outlineVariant.withValues(
                        alpha: metrics.hasActivity ? 0.42 : 0.26,
                      );
            final bgColor = isSelected
                ? scheme.primary.withValues(alpha: 0.09)
                : isCurrentMonth
                    ? scheme.primary.withValues(alpha: 0.05)
                    : metrics.hasActivity
                        ? scheme.surface
                        : scheme.surfaceContainerHighest
                            .withValues(alpha: 0.30);

            return SizedBox(
              width: tileWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onTapMonth(month),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      child: MonthTileContent(
                        title: monthNameBuilder(month),
                        subtitle: subtitleBuilder(totals),
                        totals: totals,
                        isSelected: isSelected,
                        isCurrentMonth: isCurrentMonth,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}
