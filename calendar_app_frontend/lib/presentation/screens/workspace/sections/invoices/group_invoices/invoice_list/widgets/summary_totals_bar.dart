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
      symbol: '€',
      decimalDigits: 2,
    );
    final mismatches = _num(summary?['mismatchCount']).toInt();
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
              ? 'Buscar facturas, clientes o importes…'
              : 'Search invoices, clients or amounts…',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
    final totals = HexoraCompactFinancialSummary(
      dense: true,
      inline: true,
      loading: loading,
      loadingLabel: isEs ? 'Calculando totales…' : 'Calculating totals…',
      metrics: [
        HexoraFinancialMetric(
          label: isEs ? 'Base imponible' : 'Taxable base',
          value: money.format(_num(summary?['subtotal'])),
        ),
        HexoraFinancialMetric(
          label: isEs ? 'IVA' : 'VAT',
          value: money.format(_num(summary?['taxTotal'])),
        ),
        HexoraFinancialMetric(
          label: isEs ? 'Total facturado' : 'Total invoiced',
          value: money.format(_num(summary?['total'])),
          emphasized: true,
        ),
      ],
      alert: mismatches <= 0
          ? null
          : HexoraFinancialAlert(
              label: isEs
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
    );
    final optionsAction = InvoiceToolbarOptionsMenu(
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
      onResolveLinks: () => onHeaderAction(_InvoiceHeaderAction.resolveLinks),
    );

    final toolbar = LayoutBuilder(builder: (context, constraints) {
      final scaledText = MediaQuery.textScalerOf(context).scale(14);
      final wide = constraints.maxWidth >= 1200 && scaledText <= 18;
      if (wide) {
        return SizedBox(
          height: 44,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              layoutSelector,
              const SizedBox(width: 8),
              Expanded(flex: 3, child: search),
              const SizedBox(width: 8),
              Expanded(flex: 4, child: totals),
              const SizedBox(width: 8),
              optionsAction,
            ],
          ),
        );
      }

      final compact = constraints.maxWidth < 820 || scaledText > 20;
      final totalsShareLeadingRow = leading != null && !compact;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leading != null) ...[
            SizedBox(
              height: 36,
              child: totalsShareLeadingRow
                  ? Row(
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: ClipRect(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: leading,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: totals),
                      ],
                    )
                  : ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: leading,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              layoutSelector,
              const SizedBox(width: 8),
              Expanded(child: search),
              const SizedBox(width: 8),
              optionsAction,
            ],
          ),
          if (!totalsShareLeadingRow) ...[
            const SizedBox(height: 4),
            totals,
          ],
        ],
      );
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: toolbar,
        ),
        if (!loading && (error ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Tooltip(
            message: error!,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.error_outline, size: 16, color: cs.error),
            ),
          ),
        ],
      ],
    );
  }
}
