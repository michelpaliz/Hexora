part of '../../widgets/group_invoices_invoices_view.dart';

class _InvoiceSummaryTotalsBar extends StatelessWidget {
  const _InvoiceSummaryTotalsBar({
    required this.count,
    required this.summary,
    required this.loading,
    required this.error,
    required this.fromDate,
    required this.toDate,
    required this.quickRange,
    required this.sortActions,
    required this.unlinkedOnly,
    required this.paymentSuggestionsLoading,
    required this.onDateRangeSelected,
    required this.onHeaderAction,
    this.onDownloadFiltered,
    this.onDownloadExcelFiltered,
    this.downloadingFiltered = false,
  });

  final int count;
  final Map<String, dynamic>? summary;
  final bool loading;
  final String? error;
  final DateTime? fromDate;
  final DateTime? toDate;
  final DateQuickRange quickRange;
  final List<Widget> sortActions;
  final bool unlinkedOnly;
  final bool paymentSuggestionsLoading;
  final ValueChanged<DateQuickRange> onDateRangeSelected;
  final ValueChanged<_InvoiceHeaderAction> onHeaderAction;
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
        locale: isEs ? 'es_ES' : 'en_US', symbol: '', decimalDigits: 2);
    final displayedCount =
        summary == null ? count : _num(summary?['count']).toInt();
    final mismatches = _num(summary?['mismatchCount']).toInt();
    final totalColor = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFB45309)
        : cs.secondary;

    Widget metric(String label, num value, Color color,
            {bool emphasis = false}) =>
        Semantics(
          label: '$label: ${money.format(value).trim()}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: t.caption.copyWith(
                  fontSize: 11,
                  height: 1.05,
                  letterSpacing: .35,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                money.format(value).trim(),
                style: t.bodySmall.copyWith(
                  fontSize: emphasis ? 15 : 14,
                  height: 1.1,
                  color: color,
                  fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    final leading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '$displayedCount ${isEs ? (displayedCount == 1 ? 'factura' : 'facturas') : (displayedCount == 1 ? 'invoice' : 'invoices')}',
              style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(
            isEs
                ? 'Importes de las facturas mostradas'
                : 'Displayed invoice totals',
            style: t.caption.copyWith(
                color: cs.onSurfaceVariant, fontSize: 10.5, height: 1.1),
          ),
        ]),
        const SizedBox(width: 8),
        _InvoiceFiltersMenu(
          sortActions: sortActions,
          quickRange: quickRange,
          fromDate: fromDate,
          toDate: toDate,
          onSelected: onDateRangeSelected,
        ),
      ],
    );
    final totals = Semantics(
      label: isEs
          ? 'Totales de las facturas mostradas'
          : 'Totals for the displayed invoices',
      child: Wrap(spacing: 18, runSpacing: 6, children: [
        if (loading)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
        else ...[
          metric('Base imponible', _num(summary?['subtotal']), cs.onSurface),
          metric('IVA', _num(summary?['taxTotal']), cs.onSurface),
          metric('Total facturado', _num(summary?['total']), totalColor,
              emphasis: true),
          if (mismatches > 0) ...[
            Tooltip(
              message: isEs
                  ? '$mismatches desajustes en los totales mostrados'
                  : '$mismatches mismatches in the displayed totals',
              child: Semantics(
                label: isEs
                    ? '$mismatches desajustes en los totales'
                    : '$mismatches total mismatches',
                child: Icon(Icons.warning_amber_rounded,
                    size: 16, color: cs.error),
              ),
            ),
          ],
        ],
        if (!loading && (error ?? '').trim().isNotEmpty) ...[
          Tooltip(
              message: error!,
              child: Icon(Icons.error_outline, size: 16, color: cs.error)),
        ],
      ]),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        // Keep document actions visible at the right even when totals must scroll.
        final compact = constraints.maxWidth < 680 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        if (compact) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 12, runSpacing: 6, children: [leading, actions]),
                const SizedBox(height: 6),
                totals,
              ]);
        }
        return Row(children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
              child: Align(alignment: Alignment.centerRight, child: totals)),
          const SizedBox(width: 12),
          actions,
        ]);
      }),
    );
  }
}
