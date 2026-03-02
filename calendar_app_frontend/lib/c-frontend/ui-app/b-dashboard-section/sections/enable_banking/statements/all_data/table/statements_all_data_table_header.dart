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
    required this.onAmountFilterTap,
    required this.amountFilterActive,
    required this.onInvoiceSortTap,
    required this.invoiceSortMode,
  });

  final AppLocalizations label;
  final bool isCompact;
  final bool allVisibleSelected;
  final ValueChanged<bool> onToggleAll;
  final StatementsTableTheme tableTheme;
  final VoidCallback onAmountFilterTap;
  final bool amountFilterActive;
  final VoidCallback onInvoiceSortTap;
  final int invoiceSortMode; // 0=none, 1=asc, 2=desc

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final isWide = MediaQuery.of(context).size.width > 1400;
    final balanceMaxWidth =
        isWide ? 200.0 : StatementsAllDataTableLayout.balanceMaxWidth;

    final headerStyle = typography.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: tableTheme.headerText,
      letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: StatementsAllDataTableLayout.horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: tableTheme.headerBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
          if (!isCompact) ...[
            _fixedCell(
              label.statementsHeaderBatch,
              StatementsAllDataTableLayout.batchWidth,
              headerStyle,
              align: TextAlign.center,
              tooltip: label.statementsColumnBatchTooltip,
            ),
            const SizedBox(width: StatementsAllDataTableLayout.columnGap),
          ],
          _fixedCell(
            label.statementsHeaderDate,
            StatementsAllDataTableLayout.dateWidth,
            headerStyle,
          ),
          const SizedBox(width: StatementsAllDataTableLayout.columnGap),
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
          SizedBox(
            width: StatementsAllDataTableLayout.amountWidth,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label.statementsHeaderAmount,
                    style: headerStyle,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: amountFilterActive
                      ? '${label.statementsHeaderAmount}: filtro activo'
                      : '${label.statementsHeaderAmount}: filtrar',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onAmountFilterTap,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        amountFilterActive
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                        size: 16,
                        color: amountFilterActive
                            ? tableTheme.amountPositive
                            : tableTheme.headerText.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          if (!isCompact) ...[
            const SizedBox(
                width: StatementsAllDataTableLayout.balanceClientGap),
            Expanded(
              child: Text(
                '${label.statementsHeaderClient} / Proveedor',
                style: headerStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(width: StatementsAllDataTableLayout.columnGapWide),
          SizedBox(
            width: StatementsAllDataTableLayout.invoiceWidth,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label.documentTypeInvoice,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: invoiceSortMode == 1
                      ? '${label.documentTypeInvoice}: asc'
                      : invoiceSortMode == 2
                          ? '${label.documentTypeInvoice}: desc'
                          : '${label.documentTypeInvoice}: sin ordenar',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onInvoiceSortTap,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        invoiceSortMode == 1
                            ? Icons.arrow_upward
                            : invoiceSortMode == 2
                                ? Icons.arrow_downward
                                : Icons.unfold_more,
                        size: 16,
                        color: invoiceSortMode == 0
                            ? tableTheme.headerText.withValues(alpha: 0.85)
                            : tableTheme.amountPositive,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
