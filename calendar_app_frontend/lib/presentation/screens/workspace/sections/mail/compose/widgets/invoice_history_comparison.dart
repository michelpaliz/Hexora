part of '../../mail_compose_screen.dart';

class _InvoiceHistorySection extends StatelessWidget {
  const _InvoiceHistorySection({
    required this.invoices,
    required this.expanded,
    required this.sentOnly,
    required this.hasMore,
    required this.canCompare,
    required this.comparingIds,
    required this.previewingIds,
    required this.onToggle,
    required this.onSentOnlyChanged,
    required this.onShowMore,
    required this.onPreview,
    required this.onCompare,
  });

  final List<Invoice> invoices;
  final bool expanded;
  final bool sentOnly;
  final bool hasMore;
  final bool canCompare;
  final Set<String> comparingIds;
  final Set<String> previewingIds;
  final VoidCallback onToggle;
  final ValueChanged<bool> onSentOnlyChanged;
  final VoidCallback onShowMore;
  final ValueChanged<Invoice> onPreview;
  final ValueChanged<Invoice> onCompare;

  String _date(Invoice invoice) {
    final value = invoice.issueDate ?? invoice.registeredAt;
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _amount(Invoice invoice) {
    final value = invoice.total;
    if (value == null) return '-';
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} ${invoice.currency ?? 'EUR'}';
  }

  ({String label, IconData icon, Color color}) _delivery(
    BuildContext context,
    Invoice invoice,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isSpanish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    return switch (normalizedDeliveryStatus(invoice.deliveryStatus)) {
      'delivered' => (
          label: isSpanish ? 'Entregada' : 'Delivered',
          icon: Icons.done_all_rounded,
          color: const Color(0xFF2E7D32),
        ),
      'sent' => (
          label: isSpanish ? 'Enviada' : 'Sent',
          icon: Icons.send_rounded,
          color: cs.primary,
        ),
      'failed' => (
          label: isSpanish ? 'Error de envío' : 'Delivery failed',
          icon: Icons.error_outline_rounded,
          color: cs.error,
        ),
      _ => (
          label: isSpanish ? 'No enviada' : 'Not sent',
          icon: Icons.mark_email_unread_outlined,
          color: cs.onSurfaceVariant,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    return Container(
      key: const ValueKey('mail-invoice-history-section'),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: .55))),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      isSpanish ? 'Historial de facturas' : 'Invoice history',
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 19,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Align(
              alignment: Alignment.centerRight,
              child: FilterChip(
                key: const ValueKey('mail-history-sent-filter'),
                selected: sentOnly,
                onSelected: onSentOnlyChanged,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: const Icon(Icons.send_outlined, size: 13),
                label: Text(
                  isSpanish ? 'Enviadas' : 'Sent',
                  style: t.bodySmall.copyWith(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (invoices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  isSpanish
                      ? 'No hay facturas anteriores para mostrar.'
                      : 'No previous invoices to show.',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else
              ...invoices.map((invoice) {
                final delivery = _delivery(context, invoice);
                final comparing = comparingIds.contains(invoice.id);
                final previewing =
                    previewingIds.contains('history:${invoice.id}');
                return Container(
                  key: ValueKey('mail-history-invoice-${invoice.id}'),
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: .35),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.invoiceNumber.trim().isEmpty
                                  ? invoice.id
                                  : invoice.invoiceNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _date(invoice),
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 96,
                        child: Text(
                          _amount(invoice),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: delivery.label,
                        child: SizedBox.square(
                          dimension: 28,
                          child: Icon(
                            delivery.icon,
                            size: 15,
                            color: delivery.color,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: isSpanish ? 'Vista previa' : 'Preview',
                        child: IconButton(
                          key: ValueKey('mail-history-preview-${invoice.id}'),
                          onPressed:
                              previewing ? null : () => onPreview(invoice),
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          padding: EdgeInsets.zero,
                          icon: previewing
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.visibility_outlined, size: 16),
                        ),
                      ),
                      Tooltip(
                        message: canCompare
                            ? (isSpanish ? 'Comparar' : 'Compare')
                            : (isSpanish
                                ? 'Adjunta una factura para comparar'
                                : 'Attach an invoice to compare'),
                        child: IconButton(
                          key: ValueKey('mail-history-compare-${invoice.id}'),
                          onPressed: canCompare && !comparing
                              ? () => onCompare(invoice)
                              : null,
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          padding: EdgeInsets.zero,
                          icon: comparing
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.compare_arrows_rounded,
                                  size: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (hasMore)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onShowMore,
                  icon: const Icon(Icons.expand_more_rounded, size: 16),
                  label: Text(isSpanish ? 'Ver más' : 'View more'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceComparisonDialog extends StatefulWidget {
  const _InvoiceComparisonDialog({
    required this.currentInvoices,
    required this.historicalInvoice,
  });

  final List<Invoice> currentInvoices;
  final Invoice historicalInvoice;

  @override
  State<_InvoiceComparisonDialog> createState() =>
      _InvoiceComparisonDialogState();
}

class _InvoiceComparisonDialogState extends State<_InvoiceComparisonDialog> {
  late Invoice _current = widget.currentInvoices.first;

  String _number(Invoice invoice) =>
      invoice.invoiceNumber.trim().isEmpty ? invoice.id : invoice.invoiceNumber;

  String _money(num? value, String currency) =>
      '${(value ?? 0).toStringAsFixed(2).replaceAll('.', ',')} $currency';

  String _date(Invoice invoice) {
    final value = invoice.issueDate ?? invoice.registeredAt;
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _difference(num? current, num? previous) {
    if (current == null || previous == null) return '-';
    final delta = current - previous;
    final percent =
        previous.abs() < .005 ? null : (delta / previous.abs()) * 100;
    final sign = delta > 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(2).replaceAll('.', ',')}'
        '${percent == null ? '' : ' ($sign${percent.toStringAsFixed(1)}%)'}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    final previous = widget.historicalInvoice;
    final currency = _current.currency ?? previous.currency ?? 'EUR';

    Widget metric(String label, num? current, num? historical) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: t.bodySmall)),
              SizedBox(
                width: 110,
                child:
                    Text(_money(current, currency), textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 110,
                child: Text(_money(historical, currency),
                    textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 105,
                child: Text(
                  _difference(current, historical),
                  textAlign: TextAlign.right,
                  style: t.bodySmall.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );

    Widget lines(Invoice invoice) {
      if (invoice.lines.isEmpty) {
        return Text(
          isSpanish ? 'Sin líneas disponibles' : 'No lines available',
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        );
      }
      return Column(
        children: invoice.lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '× ${line.quantity}',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isSpanish ? 'Comparar facturas' : 'Compare invoices',
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.currentInvoices.length > 1)
                DropdownButtonFormField<Invoice>(
                  initialValue: _current,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: isSpanish
                        ? 'Factura adjunta actual'
                        : 'Current attached invoice',
                  ),
                  items: widget.currentInvoices
                      .map((invoice) => DropdownMenuItem(
                            value: invoice,
                            child: Text(_number(invoice)),
                          ))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _current = value);
                  },
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${_number(_current)}\n${_date(_current)}',
                      textAlign: TextAlign.right,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${_number(previous)}\n${_date(previous)}',
                      textAlign: TextAlign.right,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 105,
                    child: Text(
                      isSpanish ? 'Diferencia' : 'Difference',
                      textAlign: TextAlign.right,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const Divider(),
              metric(isSpanish ? 'Base imponible' : 'Taxable base',
                  _current.subtotal, previous.subtotal),
              metric('IVA', _current.taxTotal, previous.taxTotal),
              metric(isSpanish ? 'Total' : 'Total', _current.total,
                  previous.total),
              const SizedBox(height: 12),
              Text(
                isSpanish
                    ? 'Las diferencias son informativas y no implican un error.'
                    : 'Differences are informational and do not imply an error.',
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_number(_current),
                            style: t.bodySmall
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        lines(_current),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_number(previous),
                            style: t.bodySmall
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        lines(previous),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
