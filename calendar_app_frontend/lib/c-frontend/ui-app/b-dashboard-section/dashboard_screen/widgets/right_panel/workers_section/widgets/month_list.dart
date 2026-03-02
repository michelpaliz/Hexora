import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';

import 'text_extensions.dart';

class MonthList extends StatelessWidget {
  final int year;
  final String locale;
  final int selectedMonth;
  final Map<int, Map<String, dynamic>> monthlyTotals;
  final void Function(int month) onTapMonth;
  final String Function(Map<String, dynamic>? totals) subtitleBuilder;

  const MonthList({
    super.key,
    required this.year,
    required this.locale,
    required this.selectedMonth,
    required this.monthlyTotals,
    required this.onTapMonth,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      itemCount: 12,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = selectedMonth == month;
        final title = DateFormat.MMMM(locale)
            .format(DateTime(year, month, 1))
            .capitalize();
        final subtitle = subtitleBuilder(monthlyTotals[month]);
        final bg = isSelected
            ? cs.primaryContainer.withOpacity(0.55)
            : cs.surfaceContainerHighest.withOpacity(0.35);
        final border = isSelected
            ? cs.primary.withOpacity(0.35)
            : cs.outlineVariant.withOpacity(0.2);

        return Stack(
          children: [
            Material(
              color: bg,
              elevation: isSelected ? 1.5 : 0,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTapMonth(month),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 20,
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                left: 12,
                top: 0,
                child: Container(
                  width: 44,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                      bottom: Radius.circular(6),
                    ),
                    border: Border.all(color: border),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
