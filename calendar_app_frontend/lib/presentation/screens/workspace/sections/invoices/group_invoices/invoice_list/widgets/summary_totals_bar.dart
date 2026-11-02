part of '../../widgets/group_invoices_invoices_view.dart';

class _InvoiceSummaryTotalsBar extends StatelessWidget {
  const _InvoiceSummaryTotalsBar({
    required this.count,
    required this.visibleColumns,
    required this.onColumnsChanged,
    required this.unlinkedOnly,
    required this.paymentSuggestionsLoading,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onHeaderAction,
    this.leading,
    this.toolbarOptions,
    this.onDownloadFiltered,
    this.onDownloadExcelFiltered,
    this.downloadingFiltered = false,
  });

  final int count;
  final Set<HexoraFinancialColumn> visibleColumns;
  final ValueChanged<Set<HexoraFinancialColumn>> onColumnsChanged;
  final bool unlinkedOnly;
  final bool paymentSuggestionsLoading;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_InvoiceHeaderAction> onHeaderAction;
  final Widget? leading;
  final InvoiceToolbarOptions? toolbarOptions;
  final VoidCallback? onDownloadFiltered;
  final VoidCallback? onDownloadExcelFiltered;
  final bool downloadingFiltered;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820 ||
              MediaQuery.textScalerOf(context).scale(14) > 18;

          return HexoraDocumentToolbar(
            statusTabs: leading ?? const SizedBox.shrink(),
            viewSwitcher: const DocumentLayoutSelector(
              key: ValueKey('invoice-layout-selector'),
              embedded: true,
            ),
            searchHint: isEs
                ? 'Buscar facturas, clientes o importes...'
                : 'Search invoices, clients or amounts...',
            searchValue: searchQuery,
            onSearchChanged: onSearchChanged,
            actions: InvoiceToolbarOptionsMenu(
              count: count,
              downloading: downloadingFiltered,
              availableColumns:
                  _InvoicesTabListState._availableFinancialColumns,
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
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceFinancialSummaryBar extends StatefulWidget {
  const _InvoiceFinancialSummaryBar({
    required this.count,
    required this.totalCount,
    required this.filtered,
    required this.visibleColumns,
    required this.summary,
    required this.loading,
    required this.error,
    required this.mismatchCount,
    required this.mismatchFilterActive,
    this.onMismatchTap,
  });

  final int count;
  final int totalCount;
  final bool filtered;
  final Set<HexoraFinancialColumn> visibleColumns;
  final Map<String, dynamic>? summary;
  final bool loading;
  final String? error;
  final int mismatchCount;
  final bool mismatchFilterActive;
  final VoidCallback? onMismatchTap;

  @override
  State<_InvoiceFinancialSummaryBar> createState() =>
      _InvoiceFinancialSummaryBarState();
}

class _InvoiceFinancialSummaryBarState
    extends State<_InvoiceFinancialSummaryBar> {
  bool _expandedOnNarrow = false;

  num _num(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  Widget _mismatchButton(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final active = widget.mismatchFilterActive;
    final amber = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF9A5B00)
        : const Color(0xFFFFC247);
    final tooltip =
        isEs ? 'Facturas con desajustes' : 'Invoices with discrepancies';
    return Semantics(
      button: true,
      selected: active,
      label: '$tooltip: ${widget.mismatchCount}',
      hint: active
          ? (isEs ? 'Quitar filtro' : 'Remove filter')
          : (isEs ? 'Filtrar facturas' : 'Filter invoices'),
      child: HexoraButton(
        key: const ValueKey('invoice-footer-mismatches'),
        onPressed: widget.onMismatchTap,
        icon: Icons.warning_amber_rounded,
        label: '${widget.mismatchCount}',
        trailingIcon: active ? Icons.close_rounded : null,
        tooltip: tooltip,
        variant: HexoraButtonVariant.ghost,
        size: HexoraButtonSize.compact,
        accentColor: amber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final money = NumberFormat.currency(
      locale: isEs ? 'es_ES' : 'en_US',
      symbol: '€',
      decimalDigits: 2,
    );
    final mismatches = widget.mismatchCount;
    final baseAmount = money.format(_num(widget.summary?['subtotal']));
    final taxAmount = money.format(_num(widget.summary?['taxTotal']));
    final totalAmount = money.format(_num(widget.summary?['total']));

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720 ||
              MediaQuery.textScalerOf(context).scale(14) > 19;
          final showAll = !narrow || _expandedOnNarrow;
          final scopeLabel = widget.filtered
              ? isEs
                  ? 'Filtradas ${widget.count} de ${widget.totalCount}'
                  : 'Filtered ${widget.count} of ${widget.totalCount}'
              : isEs
                  ? '${widget.totalCount} facturas'
                  : '${widget.totalCount} invoices';

          final summary = HexoraCompactFinancialSummary(
            key: ValueKey(showAll),
            dense: true,
            inline: true,
            loading: widget.loading,
            loadingLabel: isEs ? 'Calculando totales…' : 'Calculating totals…',
            metrics: [
              if (showAll) ...[
                HexoraFinancialMetric(
                  label: isEs ? 'Base imponible' : 'Taxable base',
                  value: baseAmount,
                  inlineWidth: 124,
                ),
                HexoraFinancialMetric(
                  label: isEs ? 'IVA' : 'VAT',
                  value: taxAmount,
                  inlineWidth: 96,
                ),
              ],
              HexoraFinancialMetric(
                label: isEs ? 'Total facturado' : 'Total invoiced',
                value: totalAmount,
                emphasized: true,
                inlineWidth: 132,
              ),
            ],
          );

          final compactFooter = Container(
            key: const ValueKey('invoice-sticky-financial-summary'),
            height: 50,
            padding: const EdgeInsetsDirectional.only(start: 12, end: 5),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: 0.82),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: narrow ? 112 : 160,
                  child: Text(
                    scopeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: AnimatedSwitcher(
                    duration: HexoraMotion.duration(
                      context,
                      HexoraMotion.standard,
                    ),
                    switchInCurve: HexoraMotion.enter,
                    switchOutCurve: HexoraMotion.exit,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    child: summary,
                  ),
                ),
                if ((widget.error ?? '').trim().isNotEmpty)
                  Tooltip(
                    message: widget.error!,
                    child: Icon(Icons.error_outline, size: 16, color: cs.error),
                  ),
                if (mismatches > 0 || widget.mismatchFilterActive) ...[
                  const SizedBox(width: 3),
                  _mismatchButton(context),
                ],
                if (narrow)
                  IconButton(
                    tooltip: _expandedOnNarrow
                        ? (isEs ? 'Contraer resumen' : 'Collapse summary')
                        : (isEs ? 'Ver Base e IVA' : 'Show base and VAT'),
                    onPressed: () => setState(
                      () => _expandedOnNarrow = !_expandedOnNarrow,
                    ),
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: Icon(
                      _expandedOnNarrow
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                    ),
                  ),
              ],
            ),
          );

          Widget? trailing;
          if ((widget.error ?? '').trim().isNotEmpty) {
            trailing = Tooltip(
              message: widget.error!,
              child: Icon(Icons.error_outline, size: 16, color: cs.error),
            );
          } else if (mismatches > 0 || widget.mismatchFilterActive) {
            trailing = _mismatchButton(context);
          }

          return CompactDocumentFinancialFooter(
            key: const ValueKey('invoice-aligned-financial-summary'),
            countLabel: scopeLabel,
            taxableBaseValue: baseAmount,
            vatValue: taxAmount,
            totalValue: totalAmount,
            visibleFinancialColumns: widget.visibleColumns,
            compactFallback: compactFooter,
            actionsWidth: 68,
            hideActionsInSplitView: true,
            showDeliveryColumn: true,
            invoiceColumnOrder: true,
            preferWideClient: true,
            loading: widget.loading,
            trailing: trailing,
          );
        },
      ),
    );
  }
}
