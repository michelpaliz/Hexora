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
  final bool downloadingFiltered;

  num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final money = NumberFormat.currency(
      locale: isSpanish ? 'es_ES' : 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    final subtotal = _num(summary?['subtotal']);
    final taxTotal = _num(summary?['taxTotal']);
    final total = _num(summary?['total']);
    final mismatchCount = _num(summary?['mismatchCount']).toInt();
    final summaryCount = _num(summary?['count']).toInt();
    final totalChipColor = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFB45309)
        : cs.secondary;
    final dateFormatter = DateFormat.yMMMd(isSpanish ? 'es_ES' : 'en_US');
    final rangeLabel = fromDate == null && toDate == null
        ? null
        : '${fromDate == null ? '...' : dateFormatter.format(fromDate!)} – ${toDate == null ? '...' : dateFormatter.format(toDate!)}';

    Widget valueChip(String label, num value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Text(
          '$label ${money.format(value).trim()}',
          style: t.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '${summary != null ? summaryCount : count} ${isSpanish ? ((summary != null ? summaryCount : count) == 1 ? 'factura' : 'facturas') : ((summary != null ? summaryCount : count) == 1 ? 'invoice' : 'invoices')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          ...sortActions.expand(
            (action) => [action, const SizedBox(width: 4)],
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: cs.outlineVariant.withValues(alpha: 0.55),
          ),
          PopupMenuButton<DateQuickRange>(
            tooltip: rangeLabel ??
                (isSpanish ? 'Filtrar por fecha' : 'Filter by date'),
            initialValue: quickRange == DateQuickRange.none ? null : quickRange,
            onSelected: onDateRangeSelected,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: DateQuickRange.month,
                checked: quickRange == DateQuickRange.month,
                child: Text(isSpanish ? 'Últimos 30 días' : 'Last 30 days'),
              ),
              CheckedPopupMenuItem(
                value: DateQuickRange.quarter,
                checked: quickRange == DateQuickRange.quarter,
                child: Text(isSpanish ? 'Últimos 3 meses' : 'Last 3 months'),
              ),
              CheckedPopupMenuItem(
                value: DateQuickRange.custom,
                checked: quickRange == DateQuickRange.custom,
                child: Text(isSpanish ? 'Personalizado…' : 'Custom…'),
              ),
              if (rangeLabel != null) const PopupMenuDivider(),
              if (rangeLabel != null)
                PopupMenuItem(
                  value: DateQuickRange.none,
                  child: Text(isSpanish ? 'Borrar filtro' : 'Clear filter'),
                ),
            ],
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: rangeLabel == null
                    ? Colors.transparent
                    : cs.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: rangeLabel == null
                      ? cs.outlineVariant.withValues(alpha: 0.2)
                      : cs.primaryContainer,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.date_range_outlined,
                size: 15,
                color: rangeLabel == null
                    ? cs.onSurfaceVariant
                    : cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (loading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.primary),
                            ),
                          )
                        else ...[
                          valueChip('Base', subtotal, cs.primary),
                          const SizedBox(width: 8),
                          valueChip('IVA', taxTotal, cs.onSurface),
                          const SizedBox(width: 8),
                          valueChip('Total', total, totalChipColor),
                          if (mismatchCount > 0) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: isSpanish
                                  ? '$mismatchCount ${mismatchCount == 1 ? 'desajuste' : 'desajustes'}'
                                  : '$mismatchCount ${mismatchCount == 1 ? 'mismatch' : 'mismatches'}',
                              child: Semantics(
                                label: isSpanish
                                    ? '$mismatchCount ${mismatchCount == 1 ? 'desajuste' : 'desajustes'}'
                                    : '$mismatchCount ${mismatchCount == 1 ? 'mismatch' : 'mismatches'}',
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: cs.error.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: cs.error.withValues(alpha: 0.32),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    size: 17,
                                    color: cs.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (!loading && (error ?? '').trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: error!,
                            child: Icon(
                              Icons.error_outline,
                              size: 16,
                              color: cs.error,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        PopupMenuButton<_InvoiceHeaderAction>(
                          tooltip: isSpanish ? 'Más acciones' : 'More actions',
                          enabled: !paymentSuggestionsLoading,
                          onSelected: onHeaderAction,
                          itemBuilder: (_) => [
                            CheckedPopupMenuItem(
                              value: _InvoiceHeaderAction.toggleUnlinked,
                              checked: unlinkedOnly,
                              child: Text(
                                isSpanish
                                    ? 'Facturas no vinculadas'
                                    : 'Unlinked invoices',
                              ),
                            ),
                            PopupMenuItem(
                              value: _InvoiceHeaderAction.resolveLinks,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.auto_fix_high_rounded,
                                  size: 18,
                                ),
                                title: Text(
                                  isSpanish
                                      ? 'Resolver vínculos…'
                                      : 'Resolve links…',
                                ),
                              ),
                            ),
                          ],
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: unlinkedOnly
                                  ? cs.tertiary.withValues(alpha: 0.10)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (unlinkedOnly
                                        ? cs.tertiary
                                        : cs.outlineVariant)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: paymentSuggestionsLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.more_horiz_rounded,
                                    size: 18,
                                    color: unlinkedOnly
                                        ? cs.tertiary
                                        : cs.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        if (onDownloadFiltered != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: isSpanish
                                ? 'Descargar facturas filtradas'
                                : 'Download filtered invoices',
                            onPressed:
                                downloadingFiltered ? null : onDownloadFiltered,
                            style: IconButton.styleFrom(
                              fixedSize: const Size(38, 38),
                              minimumSize: const Size(38, 38),
                              padding: EdgeInsets.zero,
                              foregroundColor: cs.primary,
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.04),
                              disabledBackgroundColor: cs
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.22),
                              side: BorderSide(
                                color: cs.primary.withValues(alpha: 0.35),
                              ),
                              shape: const CircleBorder(),
                            ),
                            icon: downloadingFiltered
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download_rounded,
                                    size: 17,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
