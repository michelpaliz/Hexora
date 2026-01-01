import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceListItem extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InvoiceListItem({
    super.key,
    required this.invoice,
    required this.client,
    this.onTap,
    this.onDelete,
  });

  @override
  State<InvoiceListItem> createState() => _InvoiceListItemState();
}

class _InvoiceListItemState extends State<InvoiceListItem> {
  final _linesApi = InvoiceLinesApi();
  bool _loadingMeta = false;
  String? _metaError;
  int? _lineCount;
  num? _subtotal;
  num? _taxTotal;
  num? _total;
  bool _breakdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _seedFromInvoice();
    _maybeFetchMeta();
  }

  @override
  void didUpdateWidget(covariant InvoiceListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice.id != widget.invoice.id ||
        oldWidget.invoice.lines.length != widget.invoice.lines.length ||
        oldWidget.invoice.subtotal != widget.invoice.subtotal ||
        oldWidget.invoice.taxTotal != widget.invoice.taxTotal ||
        oldWidget.invoice.total != widget.invoice.total) {
      _seedFromInvoice();
      _maybeFetchMeta();
    }
  }

  void _seedFromInvoice() {
    num lineSubtotal(InvoiceLine line) =>
        line.lineSubtotal ?? (line.quantity * line.unitPrice);
    num lineTax(InvoiceLine line) =>
        line.lineTax ?? (lineSubtotal(line) * (line.taxRate / 100));
    num lineTotal(InvoiceLine line) =>
        line.lineTotal ?? (lineSubtotal(line) + lineTax(line));

    if (widget.invoice.lines.isNotEmpty) {
      _lineCount = widget.invoice.lines.length;
      _subtotal = widget.invoice.subtotal ??
          widget.invoice.lines.fold<num>(
            0,
            (sum, line) => sum + lineSubtotal(line),
          );
      _taxTotal = widget.invoice.taxTotal ??
          widget.invoice.lines.fold<num>(0, (sum, line) => sum + lineTax(line));
      _total = widget.invoice.total ??
          widget.invoice.lines.fold<num>(
            0,
            (sum, line) => sum + lineTotal(line),
          );
    } else {
      _lineCount = null;
      _subtotal = widget.invoice.subtotal;
      _taxTotal = widget.invoice.taxTotal;
      _total = widget.invoice.total;
    }
  }

  Future<void> _maybeFetchMeta() async {
    if (!mounted) return;
    if (widget.invoice.id.trim().isEmpty) return;
    if (widget.invoice.lines.isNotEmpty) return;
    if (_subtotal != null || _taxTotal != null || _total != null) return;
    if (_loadingMeta) return;

    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });
    try {
      final lines = await _linesApi.list(widget.invoice.id);
      if (!mounted) return;

      num lineSubtotal(InvoiceLine line) =>
          line.lineSubtotal ?? (line.quantity * line.unitPrice);
      num lineTax(InvoiceLine line) =>
          line.lineTax ?? (lineSubtotal(line) * (line.taxRate / 100));
      num lineTotal(InvoiceLine line) =>
          line.lineTotal ?? (lineSubtotal(line) + lineTax(line));

      setState(() {
        _lineCount = lines.length;
        _subtotal = lines.fold<num>(0, (sum, line) => sum + lineSubtotal(line));
        _taxTotal = lines.fold<num>(0, (sum, line) => sum + lineTax(line));
        _total = lines.fold<num>(0, (sum, line) => sum + lineTotal(line));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _metaError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final invoice = widget.invoice;
    final client = widget.client;
    final dateLabel = invoice.registeredAt != null
        ? DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(invoice.registeredAt!.toLocal())
        : l.invoiceRegisteredUnknown;

    final money = NumberFormat.currency(locale: l.localeName, symbol: '€');
    const dash = '—';
    final linesCountLabel =
        _lineCount?.toString() ?? (_loadingMeta ? '…' : dash);
    final subtotalLabel = _subtotal == null
        ? (_loadingMeta ? '…' : dash)
        : money.format(_subtotal);
    final taxLabel = _taxTotal == null
        ? (_loadingMeta ? '…' : dash)
        : money.format(_taxTotal);
    final totalLabel =
        _total == null ? (_loadingMeta ? '…' : dash) : money.format(_total);
    final hasBreakdown = _subtotal != null || _taxTotal != null;

    return Card(
      elevation: 3,
      shadowColor: ThemeColors.cardShadow(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: cs.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        invoice.invoiceNumber,
                        dateLabel,
                        if (linesCountLabel != dash)
                          '${l.invoiceLinesTitle}: $linesCountLabel',
                      ].where((e) => e.trim().isNotEmpty).join(' · '),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalLabel,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    if (_breakdownExpanded && hasBreakdown) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${l.invoiceSubtotalLabel}: $subtotalLabel',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l.invoiceTaxLabel}: $taxLabel',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_metaError != null) ...[
                      const SizedBox(height: 6),
                      Tooltip(
                        message: _metaError!,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: cs.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.details,
                              style: t.bodySmall.copyWith(
                                color: cs.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(status: invoice.status ?? 'draft'),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasBreakdown)
                        IconButton(
                          tooltip: l.details,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() {
                            _breakdownExpanded = !_breakdownExpanded;
                          }),
                          icon: Icon(
                            _breakdownExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          tooltip: l.delete,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline),
                          color: cs.error,
                          onPressed: widget.onDelete,
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          color: cs.onSurfaceVariant,
                        ),
                    ],
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final bool issued = normalized.contains('issue');
    final Color bg =
        issued ? cs.secondaryContainer : cs.surfaceContainerHighest;
    final Color fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(
        normalized.isEmpty ? 'draft' : normalized,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
