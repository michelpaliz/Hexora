part of '../../widgets/group_invoices_invoices_view.dart';

class _InvoiceSummaryTotalsBar extends StatelessWidget {
  const _InvoiceSummaryTotalsBar({
    required this.count,
    required this.totalCount,
    required this.summary,
    required this.loading,
    required this.error,
    required this.visibleColumns,
    required this.onColumnsChanged,
    required this.unlinkedOnly,
    required this.paymentSuggestionsLoading,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onHeaderAction,
    this.leading,
    this.toolbarOptions,
    this.onMismatchTap,
    this.onDownloadFiltered,
    this.onDownloadExcelFiltered,
    this.downloadingFiltered = false,
  });

  final int count;
  final int totalCount;
  final Map<String, dynamic>? summary;
  final bool loading;
  final String? error;
  final Set<HexoraFinancialColumn> visibleColumns;
  final ValueChanged<Set<HexoraFinancialColumn>> onColumnsChanged;
  final bool unlinkedOnly;
  final bool paymentSuggestionsLoading;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_InvoiceHeaderAction> onHeaderAction;
  final Widget? leading;
  final InvoiceToolbarOptions? toolbarOptions;
  final VoidCallback? onMismatchTap;
  final VoidCallback? onDownloadFiltered;
  final VoidCallback? onDownloadExcelFiltered;
  final bool downloadingFiltered;

  num _num(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final money = NumberFormat.currency(
      locale: isEs ? 'es_ES' : 'en_US',
      symbol: '\u20AC',
      decimalDigits: 2,
    );
    final mismatches = _num(summary?['mismatchCount']).toInt();
    final baseAmount = money.format(_num(summary?['subtotal']));
    final taxAmount = money.format(_num(summary?['taxTotal']));
    final totalAmount = money.format(_num(summary?['total']));

    final search = SizedBox(
      height: 34,
      child: TextFormField(
        key: ValueKey(searchQuery),
        initialValue: searchQuery,
        onChanged: onSearchChanged,
        textInputAction: TextInputAction.search,
        style: t.bodySmall.copyWith(fontSize: 12.5),
        decoration: InputDecoration(
          hintText: isEs
              ? 'Buscar facturas, clientes o importes\u2026'
              : 'Search invoices, clients or amounts\u2026',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
        ),
      ),
    );

    Widget totals({required bool showSecondary, required bool compactAlert}) =>
        HexoraCompactFinancialSummary(
          dense: true,
          inline: true,
          loading: loading,
          loadingLabel:
              isEs ? 'Calculando totales\u2026' : 'Calculating totals\u2026',
          metrics: [
            if (showSecondary) ...[
              HexoraFinancialMetric(
                label: isEs ? 'Base imponible' : 'Taxable base',
                value: baseAmount,
                inlineWidth: 108,
              ),
              HexoraFinancialMetric(
                label: isEs ? 'IVA' : 'VAT',
                value: taxAmount,
                inlineWidth: 84,
              ),
            ],
            HexoraFinancialMetric(
              label: isEs ? 'Total facturado' : 'Total invoiced',
              value: totalAmount,
              emphasized: true,
              inlineWidth: 118,
            ),
          ],
          alert: mismatches <= 0
              ? null
              : HexoraFinancialAlert(
                  label: compactAlert
                      ? '$mismatches'
                      : isEs
                          ? '$mismatches ${mismatches == 1 ? 'desajuste' : 'desajustes'}'
                          : '$mismatches ${mismatches == 1 ? 'mismatch' : 'mismatches'}',
                  tooltip: isEs
                      ? 'Abrir una factura cuyos importes no cuadran'
                      : 'Open an invoice whose amounts do not add up',
                  onPressed: onMismatchTap,
                ),
        );

    const layoutSelector = DocumentLayoutSelector(
      key: ValueKey('invoice-layout-selector'),
      embedded: true,
    );

    Widget optionsAction({
      required bool compact,
      required bool showCollapsedMetrics,
    }) =>
        InvoiceToolbarOptionsMenu(
          count: count,
          downloading: downloadingFiltered,
          availableColumns: _InvoicesTabListState._availableFinancialColumns,
          visibleColumns: visibleColumns,
          onColumnsChanged: onColumnsChanged,
          unlinkedOnly: unlinkedOnly,
          paymentSuggestionsLoading: paymentSuggestionsLoading,
          toolbarOptions: toolbarOptions,
          onPdf: onDownloadFiltered,
          onExcel: onDownloadExcelFiltered,
          onToggleUnlinked: () =>
              onHeaderAction(_InvoiceHeaderAction.toggleUnlinked),
          onResolveLinks: () =>
              onHeaderAction(_InvoiceHeaderAction.resolveLinks),
          compact: compact,
          embedded: true,
          collapsedBaseAmount: showCollapsedMetrics ? baseAmount : null,
          collapsedTaxAmount: showCollapsedMetrics ? taxAmount : null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaledText = MediaQuery.textScalerOf(context).scale(14);
          final compact = constraints.maxWidth < 1180 || scaledText > 18;
          final veryCompact = constraints.maxWidth < 820 || scaledText > 20;
          final showSecondaryMetrics = !compact;
          final financialWidth = showSecondaryMetrics
              ? (mismatches > 0 ? 438.0 : 322.0)
              : (mismatches > 0 ? (veryCompact ? 160.0 : 220.0) : 118.0);
          final dividerColor = cs.outlineVariant.withValues(alpha: 0.42);

          Widget separator() => Container(
                width: 1,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: dividerColor,
              );

          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: veryCompact
                          ? 200
                          : compact
                              ? 300
                              : 340,
                    ),
                    child: leading!,
                  ),
                  separator(),
                ],
                layoutSelector,
                const SizedBox(width: 6),
                Expanded(child: search),
                separator(),
                SizedBox(
                  width: financialWidth,
                  child: totals(
                    showSecondary: showSecondaryMetrics,
                    compactAlert: veryCompact,
                  ),
                ),
                if (!loading && (error ?? '').trim().isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Tooltip(
                    message: error!,
                    child: Icon(Icons.error_outline, size: 16, color: cs.error),
                  ),
                ],
                const SizedBox(width: 4),
                optionsAction(
                  compact: compact,
                  showCollapsedMetrics: !showSecondaryMetrics,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
