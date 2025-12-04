import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimeSummarySection extends StatelessWidget {
  const TimeSummarySection({
    super.key,
    required this.start,
    required this.end,
    required this.dateFormat,
    required this.timeFormat,
    required this.selectedCount,
  });

  final DateTime start;
  final DateTime end;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dateFormat.format(start)} · ${timeFormat.format(start)} → ${timeFormat.format(end)}',
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCount == 0
                      ? l.workerRequiredError
                      : l.selectedCommitted(selectedCount),
                  style: t.caption.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
