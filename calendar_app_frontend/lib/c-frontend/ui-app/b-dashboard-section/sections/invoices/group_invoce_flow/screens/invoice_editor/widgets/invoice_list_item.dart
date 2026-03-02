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
  final VoidCallback? onEdit;
  final bool selected;

  const InvoiceListItem({
    super.key,
    required this.invoice,
    required this.client,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.selected = false,
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
  bool _suppressTap = false;

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
    final registeredDateLabel = invoice.registeredAt != null
        ? DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(invoice.registeredAt!.toLocal())
        : null;
    final occurrenceDateLabel = invoice.occurrenceDate != null
        ? DateFormat.yMMMd(l.localeName).add_Hm().format(invoice.occurrenceDate!)
        : null;

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
    final selected = widget.selected;
    final isDraft = (invoice.status ?? '').toLowerCase().contains('draft') ||
        (invoice.status ?? '').trim().isEmpty;
    final normalizedStatus = (invoice.status ?? '').toLowerCase();
    final isIssued = normalizedStatus.contains('issue');
    final isLinked = invoice.isLinkedResolved;
    final linkedCount = invoice.linkedEntriesCountSafe;
    final statusTooltip = normalizedStatus.isEmpty || isDraft
        ? l.statusDraft
        : (isIssued ? l.statusIssued : invoice.status ?? '');
    final linkedTooltip = isLinked
        ? (linkedCount > 0
            ? l.statementsRepetitiveInvoiceTooltip(linkedCount)
            : l.statementsInvoiceAlreadyLinkedBadge)
        : l.statementsUnlinked;
    final cardColor =
        selected ? cs.primaryContainer.withValues(alpha: 0.45) : cs.surface;
    final borderColor = selected
        ? cs.primary.withValues(alpha: 0.7)
        : cs.outlineVariant.withValues(alpha: 0.4);

    return Card(
      elevation: selected ? 2 : 1,
      color: cardColor,
      shadowColor: ThemeColors.cardShadow(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: borderColor,
          width: selected ? 1.2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.onTap == null
            ? null
            : () {
                if (_suppressTap) {
                  _suppressTap = false;
                  return;
                }
                widget.onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: cs.onSurfaceVariant,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          invoice.invoiceNumber,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (linesCountLabel != dash)
                          '${l.invoiceLinesTitle}: $linesCountLabel'
                          '${registeredDateLabel == null ? '' : ' � $registeredDateLabel'}',
                        if (linesCountLabel == dash &&
                            registeredDateLabel != null)
                          registeredDateLabel,
                        if (occurrenceDateLabel != null &&
                            occurrenceDateLabel != registeredDateLabel)
                          occurrenceDateLabel,
                      ].where((e) => e.trim().isNotEmpty).join(' � '),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_breakdownExpanded && hasBreakdown) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          Text(
                            '${l.invoiceSubtotalLabel}: $subtotalLabel',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${l.invoiceTaxLabel}: $taxLabel',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${l.invoiceTotalLabel}: $totalLabel',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
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
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ═══ METADATA GROUP ═══
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (invoice.recurringSeriesId?.trim().isNotEmpty == true)
                              _MetaIcon(
                                icon: Icons.repeat_rounded,
                                tooltip:
                                    '${l.createdByLabel} ${l.invoiceRecurringLabel.toLowerCase()}',
                                color: cs.primary,
                                size: 16,
                              ),
                            _MetaIcon(
                              icon: isIssued
                                  ? Icons.task_alt_outlined
                                  : Icons.edit_note_outlined,
                              tooltip: statusTooltip,
                              color: isIssued
                                  ? cs.tertiary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.6),
                              size: 16,
                            ),
                            _MetaIcon(
                              icon: isLinked
                                  ? Icons.link_rounded
                                  : Icons.link_off_rounded,
                              tooltip: linkedTooltip,
                              color: isLinked
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.6),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ═══ ACTION BUTTONS GROUP ═══
                      if (hasBreakdown)
                        _ActionIconButton(
                          icon: _breakdownExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          tooltip: l.details,
                          color: cs.onSurfaceVariant,
                          onPressed: () => setState(() {
                            _breakdownExpanded = !_breakdownExpanded;
                          }),
                        ),
                      if (isDraft && widget.onEdit != null)
                        _ActionIconButton(
                          icon: Icons.edit_outlined,
                          tooltip: l.edit,
                          color: cs.primary,
                          onPressed: () {
                            _suppressTap = true;
                            widget.onEdit!();
                          },
                        ),
                      if (widget.onDelete != null) ...[
                        Container(
                          width: 1,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                        _ActionIconButton(
                          icon: Icons.delete_outline,
                          tooltip: l.delete,
                          color: cs.error,
                          onPressed: () {
                            _suppressTap = true;
                            widget.onDelete!();
                          },
                        ),
                      ],
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

class _MetaIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final double size;

  const _MetaIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(4),
      splashRadius: 18,
      icon: Icon(icon, size: 20),
      color: color.withValues(alpha: 0.8),
      onPressed: onPressed,
    );
  }
}
