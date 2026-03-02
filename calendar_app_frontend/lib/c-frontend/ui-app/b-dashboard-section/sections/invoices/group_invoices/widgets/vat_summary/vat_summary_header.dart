import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class VatSummaryHeader extends StatelessWidget {
  final int year;
  final String rangeLabel;
  final String deadlineLabel;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final TabController tabs;

  const VatSummaryHeader({
    super.key,
    required this.year,
    required this.rangeLabel,
    required this.deadlineLabel,
    required this.onPrevYear,
    required this.onNextYear,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedQuarter = tabs.index + 1;

    Widget quarterButton({
      required int quarter,
      required IconData icon,
      required String tooltip,
    }) {
      final selected = selectedQuarter == quarter;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => tabs.animateTo(quarter - 1),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? cs.primaryContainer : Colors.transparent,
              border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
              ),
            ),
            child: Icon(
              icon,
              size: 13,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Align(
        alignment: Alignment.topRight,
        child: Transform.translate(
          offset: const Offset(0, -16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event, size: 15, color: cs.onSurface),
                const SizedBox(width: 6),
                Text(
                  rangeLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: deadlineLabel,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(
                      Icons.schedule,
                      size: 14,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Year: $year',
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                quarterButton(
                  quarter: 1,
                  icon: Icons.looks_one_outlined,
                  tooltip: l.vatSummaryQuarterQ1,
                ),
                const SizedBox(width: 6),
                quarterButton(
                  quarter: 2,
                  icon: Icons.looks_two_outlined,
                  tooltip: l.vatSummaryQuarterQ2,
                ),
                const SizedBox(width: 6),
                quarterButton(
                  quarter: 3,
                  icon: Icons.looks_3_outlined,
                  tooltip: l.vatSummaryQuarterQ3,
                ),
                const SizedBox(width: 6),
                quarterButton(
                  quarter: 4,
                  icon: Icons.looks_4_outlined,
                  tooltip: l.vatSummaryQuarterQ4,
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: l.vatSummaryPrevYear,
                  child: InkWell(
                    onTap: onPrevYear,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: l.vatSummaryNextYear,
                  child: InkWell(
                    onTap: onNextYear,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        size: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
