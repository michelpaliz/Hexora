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

    Widget valueChip(String label, num value, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Text('$label ${money.format(value).trim()}',
              style: t.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w900)),
        );

    final leading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
            '$displayedCount ${isEs ? (displayedCount == 1 ? 'factura' : 'facturas') : (displayedCount == 1 ? 'invoice' : 'invoices')}',
            style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
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
    final totals = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (loading)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
        else ...[
          valueChip('Base', _num(summary?['subtotal']), cs.primary),
          const SizedBox(width: 8),
          valueChip('IVA', _num(summary?['taxTotal']), cs.onSurface),
          const SizedBox(width: 8),
          valueChip('Total', _num(summary?['total']), totalColor),
          if (mismatches > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message:
                  isEs ? '$mismatches desajustes' : '$mismatches mismatches',
              child:
                  Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
            ),
          ],
        ],
        if (!loading && (error ?? '').trim().isNotEmpty) ...[
          const SizedBox(width: 8),
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
            PopupMenuItem(
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
            fixedSize: const Size(36, 36),
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor:
                unlinkedOnly ? cs.primaryContainer : Colors.transparent,
            foregroundColor:
                unlinkedOnly ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal, child: leading),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: totals),
                  const SizedBox(width: 8),
                  actions,
                ]),
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
