import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'statements_all_data_table_layout.dart';
import 'statements_all_data_table_theme.dart';

class StatementsAllDataTableHeader extends StatelessWidget {
  const StatementsAllDataTableHeader({
    super.key,
    required this.label,
    required this.isCompact,
    required this.allVisibleSelected,
    required this.onToggleAll,
    required this.tableTheme,
  });

  final AppLocalizations label;
  final bool isCompact;
  final bool allVisibleSelected;
  final ValueChanged<bool> onToggleAll;
  final StatementsTableTheme tableTheme;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final isWide = MediaQuery.of(context).size.width > 1400;
    final balanceMaxWidth =
        isWide ? 200.0 : StatementsAllDataTableLayout.balanceMaxWidth;
    final balanceClientGap =
        isWide ? 40.0 : StatementsAllDataTableLayout.balanceClientGap;

    final headerStyle = typography.bodyMedium.copyWith(
      fontWeight: FontWeight.w800,
      color: tableTheme.headerText,
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: StatementsAllDataTableLayout.horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: tableTheme.headerBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: StatementsAllDataTableLayout.leadingSpacer),

          SizedBox(
            width: StatementsAllDataTableLayout.checkWidth,
            child: Checkbox(
              value: allVisibleSelected,
              onChanged: (checked) => onToggleAll(checked == true),
            ),
          ),

          // Batch column (non-compact only)
          if (!isCompact) ...[
            _fixedCell(
              label.statementsHeaderBatch,
              StatementsAllDataTableLayout.batchWidth,
              headerStyle,
              tooltip: label.statementsColumnBatchTooltip,
            ),
            const SizedBox(width: StatementsAllDataTableLayout.columnGap),
          ],

          // Date column (fixed)
          _fixedCell(
            label.statementsHeaderDate,
            StatementsAllDataTableLayout.dateWidth,
            headerStyle,
          ),

          const SizedBox(width: StatementsAllDataTableLayout.columnGap),

          // Description column (capped)
          if (isCompact)
            Expanded(
              flex: 4,
              child: Text(
                label.statementsHeaderDescription,
                style: headerStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: StatementsAllDataTableLayout.descMinWidth,
                maxWidth: StatementsAllDataTableLayout.descMaxWidth,
              ),
              child: Text(
                label.statementsHeaderDescription,
                style: headerStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

          const SizedBox(width: StatementsAllDataTableLayout.columnGap),

          // Amount (fixed, right aligned)
          _fixedCell(
            label.statementsHeaderAmount,
            StatementsAllDataTableLayout.amountWidth,
            headerStyle,
            align: TextAlign.right,
          ),

          // ✅ Balance (flexible + constrained, right aligned)
          if (!isCompact) ...[
            const SizedBox(width: StatementsAllDataTableLayout.columnGap),
            SizedBox(
              width: balanceMaxWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  label.statementsHeaderBalance,
                  textAlign: TextAlign.right,
                  style: headerStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],

          SizedBox(width: balanceClientGap),

          // ✅ Client (EXPANDED to fill remaining right space)
          Expanded(
            flex: 3,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: StatementsAllDataTableLayout.clientMinWidth,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  label.statementsHeaderClient,
                  textAlign: TextAlign.right,
                  style: headerStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),

          const SizedBox(width: StatementsAllDataTableLayout.columnGapWide),

          _fixedCell(
            label.documentTypeInvoice,
            StatementsAllDataTableLayout.invoiceWidth,
            headerStyle,
            align: TextAlign.center,
          ),

          const SizedBox(width: StatementsAllDataTableLayout.columnGapWide),

          _fixedCell(
            label.statementsHeaderActions,
            StatementsAllDataTableLayout.actionsWidth,
            headerStyle,
            align: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _fixedCell(
    String text,
    double width,
    TextStyle style, {
    TextAlign align = TextAlign.left,
    String? tooltip,
  }) {
    final content = Text(
      text,
      style: style,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    return SizedBox(
      width: width,
      child:
          tooltip == null ? content : Tooltip(message: tooltip, child: content),
    );
  }
}
