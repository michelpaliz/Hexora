import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/invoice_delivery_utils.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceListItem extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onIssue;
  final bool selected;

  const InvoiceListItem({
    super.key,
    required this.invoice,
    required this.client,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onIssue,
    this.selected = false,
  });

  @override
  State<InvoiceListItem> createState() => _InvoiceListItemState();
}

class _InvoiceListItemState extends State<InvoiceListItem> {
  final _linesApi = InvoiceLinesApi();

  bool _loadingMeta = false;
  int? _lineCount;
  num? _subtotal;
  num? _taxTotal;
  num? _total;

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

  num _lineSubtotal(InvoiceLine line) =>
      line.lineSubtotal ?? (line.quantity * line.unitPrice);

  num _lineTax(InvoiceLine line) =>
      line.lineTax ?? (_lineSubtotal(line) * (line.taxRate / 100));

  num _lineTotal(InvoiceLine line) =>
      line.lineTotal ?? (_lineSubtotal(line) + _lineTax(line));

  void _seedFromInvoice() {
    final inv = widget.invoice;
    if (inv.lines.isNotEmpty) {
      _lineCount = inv.lines.length;
      _subtotal = inv.subtotal ??
          inv.lines.fold<num>(0, (sum, line) => sum + _lineSubtotal(line));
      _taxTotal = inv.taxTotal ??
          inv.lines.fold<num>(0, (sum, line) => sum + _lineTax(line));
      _total = inv.total ??
          inv.lines.fold<num>(0, (sum, line) => sum + _lineTotal(line));
      return;
    }

    _lineCount = null;
    _subtotal = inv.subtotal;
    _taxTotal = inv.taxTotal;
    _total = inv.total;
  }

  Future<void> _maybeFetchMeta() async {
    if (!mounted || _loadingMeta) return;
    if (widget.invoice.id.trim().isEmpty) return;
    if (widget.invoice.lines.isNotEmpty) return;
    if (_lineCount != null) return;

    setState(() => _loadingMeta = true);
    try {
      final lines = await _linesApi.list(widget.invoice.id);
      if (!mounted) return;
      setState(() {
        _lineCount = lines.length;
        _subtotal = lines.fold<num>(0, (sum, line) => sum + _lineSubtotal(line));
        _taxTotal = lines.fold<num>(0, (sum, line) => sum + _lineTax(line));
        _total = lines.fold<num>(0, (sum, line) => sum + _lineTotal(line));
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final date = widget.invoice.issueDate ??
        widget.invoice.registeredAt ??
        widget.invoice.occurrenceDate;
    final dateLabel = date == null
        ? ''
        : DateFormat.yMMMd(l.localeName).add_Hm().format(date.toLocal());

    final linesCountLabel = _lineCount?.toString() ?? (_loadingMeta ? '...' : '-');
    final money = NumberFormat.currency(locale: l.localeName, symbol: 'EUR ');
    String moneyOrDash(num? value) => value == null ? '-' : money.format(value);

    final hasBreakdown = _subtotal != null || _taxTotal != null || _total != null;
    final isIssued = (widget.invoice.status ?? '').toLowerCase().contains('issue');
    final isLinked = widget.invoice.isLinkedResolved;
    final delivery = invoiceDeliveryViewData(widget.invoice.deliveryStatus);
    final normalizedDeliveryStatus =
        normalizeDeliveryStatus(widget.invoice.deliveryStatus);
    final sentAtLabel = widget.invoice.sentAt == null
        ? null
        : DateFormat.yMMMd(l.localeName).add_Hm().format(widget.invoice.sentAt!.toLocal());
    final channelLabel = invoiceDeliveryChannelLabelEs(widget.invoice.deliveryChannel);
    final deliveryIcon = switch (normalizedDeliveryStatus) {
      'sent' => Icons.mark_email_read_outlined,
      'failed' => Icons.error_outline,
      _ => Icons.mark_email_unread_outlined,
    };
    final metadataOffColor = cs.onSurface.withValues(alpha: 0.88);
    final metadataDisclosureColor = cs.primary.withValues(alpha: 0.9);
    final statusIconColor = isIssued ? cs.primary : metadataOffColor;
    final linkIconColor = isLinked ? cs.tertiary : metadataOffColor;
    final effectiveDeliveryColor = switch (normalizedDeliveryStatus) {
      'sent' => cs.primary,
      'failed' => cs.error,
      _ => metadataOffColor,
    };
    final deliveryTooltip = [
      delivery.labelEs,
      if (sentAtLabel != null) sentAtLabel,
      if (normalizedDeliveryStatus == 'sent') channelLabel,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      color: widget.selected
          ? cs.primaryContainer.withValues(alpha: 0.45)
          : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.selected
              ? cs.primary.withValues(alpha: 0.7)
              : cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: cs.primary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.invoice.invoiceNumber,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ═══ METADATA GROUP ═══
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.75),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: isIssued ? l.statusIssued : l.statusDraft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(
                                    Icons.sync_alt,
                                    size: 16,
                                    color: statusIconColor,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: isLinked
                                    ? l.statementsInvoiceAlreadyLinkedBadge
                                    : l.statementsUnlinked,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(
                                    isLinked ? Icons.link : Icons.link_off,
                                    size: 16,
                                    color: linkIconColor,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: deliveryTooltip,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(
                                    deliveryIcon,
                                    size: 16,
                                    color: effectiveDeliveryColor,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: metadataDisclosureColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l.invoiceLinesTitle}: $linesCountLabel${dateLabel.isEmpty ? '' : ' - $dateLabel'}',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasBreakdown) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 2,
                        children: [
                          Text(
                            'Subtotal: ${moneyOrDash(_subtotal)}',
                            style: t.bodySmall.copyWith(color: cs.onSurface),
                          ),
                          Text(
                            'IVA: ${moneyOrDash(_taxTotal)}',
                            style: t.bodySmall.copyWith(color: cs.onSurface),
                          ),
                          Text(
                            'Total: ${moneyOrDash(_total)}',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // ═══ ACTION BUTTONS GROUP ═══
              const SizedBox(width: 8),
              if (widget.onEdit != null)
                IconButton(
                  onPressed: widget.onEdit,
                  tooltip: l.edit,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  splashRadius: 18,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: cs.primary.withValues(alpha: 0.8),
                ),
              if (widget.onIssue != null)
                IconButton(
                  onPressed: widget.onIssue,
                  tooltip: l.invoiceIssueCta,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  splashRadius: 18,
                  icon: const Icon(Icons.publish_outlined, size: 20),
                  color: cs.tertiary.withValues(alpha: 0.8),
                ),
              if (widget.onDelete != null) ...[
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  tooltip: l.delete,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  splashRadius: 18,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: cs.error.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
