part of '../../widgets/group_invoices_invoices_view.dart';

class _InvoiceSummaryTotalsBar extends StatelessWidget {
  const _InvoiceSummaryTotalsBar({
    required this.count,
    required this.totalCount,
    required this.summary,
    required this.loading,
    required this.error,
    required this.fromDate,
    required this.toDate,
    required this.quickRange,
    required this.sortActions,
    required this.unlinkedOnly,
    required this.paymentSuggestionsLoading,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onDateRangeSelected,
    required this.onHeaderAction,
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
  final DateTime? fromDate;
  final DateTime? toDate;
  final DateQuickRange quickRange;
  final List<Widget> sortActions;
  final bool unlinkedOnly;
  final bool paymentSuggestionsLoading;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DateQuickRange> onDateRangeSelected;
  final ValueChanged<_InvoiceHeaderAction> onHeaderAction;
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
      height: 38,
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
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InvoiceFiltersMenu(
          sortActions: sortActions,
          quickRange: quickRange,
          fromDate: fromDate,
          toDate: toDate,
          onSelected: onDateRangeSelected,
        ),
        const SizedBox(width: 8),
        _InvoiceDownloadMenu(
          count: count,
          loading: downloadingFiltered,
          onPdf: onDownloadFiltered,
          onExcel: onDownloadExcelFiltered,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<_InvoiceHeaderAction>(
          tooltip: isEs ? 'Más acciones' : 'More actions',
          position: PopupMenuPosition.under,
          onSelected: onHeaderAction,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
              value: _InvoiceHeaderAction.toggleUnlinked,
              checked: unlinkedOnly,
              child:
                  Text(isEs ? 'Facturas no vinculadas' : 'Unlinked invoices'),
            ),
            NavigationPopupMenuItem(
              value: _InvoiceHeaderAction.resolveLinks,
              enabled: !paymentSuggestionsLoading,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_fix_high_rounded, size: 18),
                title: Text(isEs ? 'Resolver vínculos…' : 'Resolve links…'),
              ),
            ),
          ],
          style: IconButton.styleFrom(
            visualDensity: VisualDensity.standard,
            fixedSize: const Size(32, 32),
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor:
                unlinkedOnly ? cs.primaryContainer : Colors.transparent,
            foregroundColor:
                unlinkedOnly ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
          icon: paymentSuggestionsLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.more_horiz_rounded, size: 18),
        ),
      ],
    );

    final toolbar = LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 760 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (constraints.maxWidth < 560) ...[
              SizedBox(width: double.infinity, child: search),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: actions),
            ] else
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 8),
                  actions,
                ],
              ),
          ],
        );
      }
      return Row(children: [
        Expanded(child: search),
        const SizedBox(width: 10),
        actions,
      ]);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: toolbar,
        ),
        const SizedBox(height: 8),
        totals,
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
