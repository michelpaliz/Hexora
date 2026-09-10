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
    required this.onDescriptionFilterTap,
    required this.descriptionFilterActive,
    required this.onNotesFilterTap,
    required this.notesFilterActive,
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
  final VoidCallback onDescriptionFilterTap;
  final bool descriptionFilterActive;
  final VoidCallback onNotesFilterTap;
  final bool notesFilterActive;
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
          _compactFilterCell(
            context,
            text: label.statementsHeaderDate,
            width: StatementsAllDataTableLayout.dateWidth,
            style: headerStyle,
            active: dateFilterActive,
            icon: Icons.calendar_month_rounded,
            tooltip: dateFilterActive
                ? '${label.statementsHeaderDate}: filtro activo'
                : '${label.statementsHeaderDate}: filtrar',
            onTap: onDateFilterTap,
          ),
          const SizedBox(width: StatementsAllDataTableLayout.columnGap),
          if (isCompact)
            Expanded(
              flex: 4,
              child: _compactFilterCell(
                context,
                text: label.statementsHeaderDescription,
                style: headerStyle,
                active: descriptionFilterActive,
                icon: Icons.search_rounded,
                tooltip: descriptionFilterActive
                    ? '${label.statementsHeaderDescription}: búsqueda activa'
                    : '${label.statementsHeaderDescription}: buscar',
                onTap: onDescriptionFilterTap,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: StatementsAllDataTableLayout.descMinWidth,
                maxWidth: StatementsAllDataTableLayout.descMaxWidth,
              ),
              child: _compactFilterCell(
                context,
                text: label.statementsHeaderDescription,
                style: headerStyle,
                active: descriptionFilterActive,
                icon: Icons.search_rounded,
                tooltip: descriptionFilterActive
                    ? '${label.statementsHeaderDescription}: búsqueda activa'
                    : '${label.statementsHeaderDescription}: buscar',
                onTap: onDescriptionFilterTap,
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
              _filterableCell(
                context,
                text: Localizations.localeOf(context)
                        .languageCode
                        .toLowerCase()
                        .startsWith('es')
                    ? 'Notas'
                    : 'Notes',
                width: StatementsAllDataTableLayout.notesWidth,
                style: headerStyle,
                active: notesFilterActive,
                tooltip: notesFilterActive
                    ? 'Notas: bÃºsqueda activa'
                    : 'Notas: buscar',
                onTap: onNotesFilterTap,
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

  Widget _compactFilterCell(
    BuildContext context, {
    required String text,
    double? width,
    required TextStyle style,
    required bool active,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final content = Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: style,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip,
            child: Material(
              color: active
                  ? cs.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: BorderSide(
                  color: active
                      ? cs.primary.withValues(alpha: 0.3)
                      : tableTheme.border.withValues(alpha: 0.45),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 28,
                  child: Icon(
                    icon,
                    size: 17,
                    color: active ? cs.primary : tableTheme.headerText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return width == null ? content : SizedBox(width: width, child: content);
  }
}
