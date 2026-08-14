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
    required this.isTablet,
    required this.allVisibleSelected,
    required this.onToggleAll,
    required this.tableTheme,
    required this.onDateFilterTap,
    required this.dateFilterActive,
    required this.onAmountFilterTap,
    required this.amountFilterActive,
    required this.onClientProviderFilterTap,
    required this.clientProviderFilterActive,
    required this.onInvoiceSortTap,
    required this.invoiceSortMode,
  });

  final AppLocalizations label;
  final bool isCompact;
  final bool isTablet;
  final bool allVisibleSelected;
  final ValueChanged<bool> onToggleAll;
  final StatementsTableTheme tableTheme;
  final VoidCallback onDateFilterTap;
  final bool dateFilterActive;
  final VoidCallback onAmountFilterTap;
  final bool amountFilterActive;
  final VoidCallback onClientProviderFilterTap;
  final bool clientProviderFilterActive;
  final VoidCallback onInvoiceSortTap;
  final int invoiceSortMode; // 0=none, 1=asc, 2=desc

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final isWide = MediaQuery.of(context).size.width > 1400;
    final balanceMaxWidth =
        isWide ? 200.0 : StatementsAllDataTableLayout.balanceMaxWidth;
    final isDesktop = !isCompact && !isTablet;
    final actionsWidth = isDesktop
        ? StatementsAllDataTableLayout.actionsWidth
        : StatementsAllDataTableLayout.compactActionsWidth;

    final headerStyle = typography.bodySmall.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: tableTheme.headerText,
      letterSpacing: 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: tableTheme.headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tableTheme.border.withValues(alpha: 0.55),
        ),
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
          if (isDesktop) ...[
            _fixedCell(
              label.statementsHeaderBatch,
              StatementsAllDataTableLayout.batchWidth,
              headerStyle,
              align: TextAlign.center,
              tooltip: label.statementsColumnBatchTooltip,
            ),
            const SizedBox(width: StatementsAllDataTableLayout.columnGap),
          ],
          _filterableCell(
            context,
            text: label.statementsHeaderDate,
            width: StatementsAllDataTableLayout.dateWidth,
            style: headerStyle,
            active: dateFilterActive,
            tooltip: dateFilterActive
                ? '${label.statementsHeaderDate}: filtro activo'
                : '${label.statementsHeaderDate}: filtrar',
            onTap: onDateFilterTap,
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
          if (isDesktop) ...[
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
            SizedBox(
              width:
                  isTablet ? 12 : StatementsAllDataTableLayout.balanceClientGap,
            ),
            Expanded(
              child: _filterableCell(
                context,
                text: Localizations.localeOf(context)
                        .languageCode
                        .toLowerCase()
                        .startsWith('es')
                    ? 'Contacto'
                    : 'Contact',
                style: headerStyle,
                active: clientProviderFilterActive,
                tooltip: clientProviderFilterActive
                    ? '${label.statementsHeaderClient} / Proveedor: filtro activo'
                    : '${label.statementsHeaderClient} / Proveedor: filtrar',
                onTap: onClientProviderFilterTap,
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: StatementsAllDataTableLayout.columnGapWide),
              _fixedCell(
                Localizations.localeOf(context)
                        .languageCode
                        .toLowerCase()
                        .startsWith('es')
                    ? 'Notas'
                    : 'Notes',
                StatementsAllDataTableLayout.notesWidth,
                headerStyle,
              ),
            ],
          ],
          const SizedBox(width: StatementsAllDataTableLayout.columnGapWide),
          SizedBox(
            width: StatementsAllDataTableLayout.invoiceWidth,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Localizations.localeOf(context)
                            .languageCode
                            .toLowerCase()
                            .startsWith('es')
                        ? 'Nº factura'
                        : 'Invoice no.',
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
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: invoiceSortMode == 0
                            ? Colors.transparent
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        invoiceSortMode == 1
                            ? Icons.arrow_upward_rounded
                            : invoiceSortMode == 2
                                ? Icons.arrow_downward_rounded
                                : Icons.unfold_more_rounded,
                        size: invoiceSortMode == 0 ? 16 : 18,
                        color: invoiceSortMode == 0
                            ? tableTheme.headerText.withValues(alpha: 0.85)
                            : Theme.of(context).colorScheme.primary,
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
            actionsWidth,
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

  Widget _filterableCell(
    BuildContext context, {
    required String text,
    double? width,
    required TextStyle style,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
    TextAlign align = TextAlign.left,
  }) {
    final cs = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: width == null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Expanded(
          child: Text(
            text,
            style: style,
            textAlign: align,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                active ? Icons.filter_alt : Icons.filter_alt_outlined,
                size: 16,
                color: active
                    ? cs.primary
                    : tableTheme.headerText.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ],
    );

    if (width == null) return content;
    return SizedBox(width: width, child: content);
  }
}
