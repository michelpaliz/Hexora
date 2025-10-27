import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';

class MonthGrid extends StatelessWidget {
  final int year;
  final int? selectedMonth; // NEW: highlight selection
  final Map<int, Map<String, dynamic>> monthlyTotals; // month → totals
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
    final t = AppTypography.of(context);
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    // Responsive columns
    int crossAxisCount = 2;
    if (width >= 900) {
      crossAxisCount = 4;
    } else if (width >= 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Fixed height per tile protects against overflow of the Row
        mainAxisExtent: 68, // ← tweak to taste (64–76 works well)
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isCurrentMonth = (now.year == year && now.month == month);
        final isSelected = selectedMonth == month;
        final totals = monthlyTotals[month];
        final title = monthNameBuilder(month);
        final subtitle = subtitleBuilder(totals);

        return Card(
          elevation: (isSelected || isCurrentMonth) ? 2 : 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: isSelected
              ? scheme.primaryContainer.withOpacity(0.35)
              : isCurrentMonth
                  ? scheme.primaryContainer.withOpacity(0.20)
                  : scheme.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onTapMonth(month),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 20,
                    color:
                        isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium.copyWith(
                            fontWeight: (isSelected || isCurrentMonth)
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
