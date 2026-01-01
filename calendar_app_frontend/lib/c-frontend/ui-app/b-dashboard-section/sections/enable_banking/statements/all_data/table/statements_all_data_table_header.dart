import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class StatementsAllDataTableHeader extends StatelessWidget {
  const StatementsAllDataTableHeader({
    super.key,
    required this.label,
    required this.isCompact,
    required this.allVisibleSelected,
    required this.onToggleAll,
  });

  final AppLocalizations label;
  final bool isCompact;
  final bool allVisibleSelected;
  final ValueChanged<bool> onToggleAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);

    // ✅ Tighten description so it doesn't steal space from right-side columns
    const descMinWidth = 220.0;
    const descMaxWidth = 260.0;

    // ✅ Guarantee room for finance-critical columns
    const amountWidth = 140.0; // was 110
    const balanceWidth = 150.0; // was 120
    const clientWidth = 200.0; // was 170
    const actionsWidth = 112.0; // was 140

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              value: allVisibleSelected,
              onChanged: (checked) => onToggleAll(checked == true),
            ),
          ),

          // Batch column (non-compact only)
          if (!isCompact) ...[
            SizedBox(
              width: 90,
              child: Tooltip(
                message: label.statementsColumnBatchTooltip,
                child: Text(
                  label.statementsHeaderBatch,
                  style: typography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Date column
          SizedBox(
            width: 100,
            child: Text(
              label.statementsHeaderDate,
              style: typography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Description column: flexible but capped
          if (isCompact)
            Expanded(
              flex: 4, // ✅ was 6; give more room to the right columns
              child: Text(
                label.statementsHeaderDescription,
                style:
                    typography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: descMinWidth,
                maxWidth: descMaxWidth,
              ),
              child: Text(
                label.statementsHeaderDescription,
                style:
                    typography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

          // Details column hidden for now.
          const SizedBox(width: 8),

          // Amount column (right aligned)
          SizedBox(
            width: amountWidth,
            child: Text(
              label.statementsHeaderAmount,
              textAlign: TextAlign.right,
              style: typography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Balance column (non-compact only, right aligned)
          if (!isCompact) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: balanceWidth,
              child: Text(
                label.statementsHeaderBalance,
                textAlign: TextAlign.right, // ✅ was center; better for numbers
                style: typography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(width: 8),

          // Client column (left aligned reads better for text)
          SizedBox(
            width: clientWidth,
            child: Text(
              label.statementsHeaderClient,
              textAlign:
                  TextAlign.left, // ✅ was center; better for names/status
              style: typography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Actions column (narrower)
          SizedBox(
            width: isCompact ? 44 : actionsWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                label.statementsHeaderActions,
                style: typography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
