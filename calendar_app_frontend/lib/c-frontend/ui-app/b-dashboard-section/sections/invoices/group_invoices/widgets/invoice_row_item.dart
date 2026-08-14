import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
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
  final VoidCallback? onPreview;
  final VoidCallback? onInspectRecurrence;
  final bool warning;
  final String? warningLabel;
  final bool monthWarning;
  final String? monthWarningLabel;
  final String? monthWarningTooltip;
  final bool selected;

  const InvoiceListItem({
    super.key,
    required this.invoice,
    required this.client,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onIssue,
    this.onPreview,
    this.onInspectRecurrence,
    this.warning = false,
    this.warningLabel,
    this.monthWarning = false,
    this.monthWarningLabel,
    this.monthWarningTooltip,
    this.selected = false,
  });

  @override
  State<InvoiceListItem> createState() => _InvoiceListItemState();
}

class _InvoiceListItemState extends State<InvoiceListItem> {
  static const double _actionIconGap = 6;

  final _linesApi = InvoiceLinesApi();

  bool _loadingMeta = false;
  bool _hovered = false;
  bool _detailsExpanded = false;
  int? _lineCount;
  num? _subtotal;
  num? _taxTotal;
  num? _total;
  num? _discountAmount;
  num? _discountPercent;

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
    final inv = widget.invoice;
    _discountAmount = inv.discountAmount;
    _discountPercent = inv.discountPercent;
    _lineCount = inv.lines.isEmpty ? null : inv.lines.length;
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
      final inv = widget.invoice;
      setState(() {
        _lineCount = lines.length;
        _subtotal = inv.subtotal;
        _taxTotal = inv.taxTotal;
        _total = inv.total;
        _discountAmount = inv.discountAmount;
        _discountPercent = inv.discountPercent;
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
    final isLight = Theme.of(context).brightness == Brightness.light;

    final date = widget.invoice.issueDate ??
        widget.invoice.registeredAt ??
        widget.invoice.occurrenceDate;
    final dateLabel = date == null
        ? ''
        : DateFormat.yMMMd(l.localeName).format(date.toLocal());

    final linesCountLabel =
        _lineCount?.toString() ?? (_loadingMeta ? '…' : '-');
    final money = NumberFormat.currency(locale: l.localeName, symbol: '€');

    final backendTotalLabel = (widget.invoice.totalFormatted ?? '').trim();
    final totalLabel = _total != null
        ? money.format(_total)
        : (backendTotalLabel.isNotEmpty ? backendTotalLabel : '');

    final settlement = widget.invoice.finalSettlement;
    final settlementDeduction = (settlement?.deductedTotal ?? 0).toDouble();
    final discountByAmount = (_discountAmount ?? 0).toDouble();
    final discountByPercent = discountByAmount <= 0 &&
            (_discountPercent ?? 0) > 0
        ? ((_subtotal ?? 0).toDouble() * (_discountPercent!.toDouble() / 100))
        : 0.0;
    final isIssued =
        (widget.invoice.status ?? '').toLowerCase().contains('issue');
    final isLinked = widget.invoice.isLinkedResolved;
    final delivery = invoiceDeliveryViewData(widget.invoice.deliveryStatus);
    final normalizedDeliveryStatus =
        normalizeDeliveryStatus(widget.invoice.deliveryStatus);
    final sentAtLabel = widget.invoice.sentAt == null
        ? null
        : DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(widget.invoice.sentAt!.toLocal());
    final channelLabel =
        invoiceDeliveryChannelLabelEs(widget.invoice.deliveryChannel);
    final invoiceType = (widget.invoice.invoiceType ?? '').trim().toLowerCase();
    final showInvoiceType = invoiceType == 'advance' || invoiceType == 'final';
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final showsAdvanceDeduction =
        invoiceType == 'final' && settlementDeduction > 0;
    final effectiveDiscount = showsAdvanceDeduction
        ? settlementDeduction
        : (discountByAmount > 0 ? discountByAmount : discountByPercent);
    final hasDiscount = effectiveDiscount > 0;
    final discountLabel = showsAdvanceDeduction
        ? (() {
            final n = (settlement?.advanceInvoiceNumber ?? '').trim();
            final b = isEs ? 'Anticipo' : 'Advance';
            return n.isEmpty ? b : '$b ${settlement!.advanceInvoiceNumber}';
          })()
        : (isEs ? 'Descuento' : 'Discount');
    final issuerName = widget.invoice.issuedByDisplayName;
    final issuedAt = widget.invoice.issuedAtResolved;
    final issuedAtLabel = issuedAt == null
        ? null
        : DateFormat.yMMMd(l.localeName).add_Hm().format(issuedAt.toLocal());
    final issuedByValue =
        issuerName ?? (isEs ? 'Emisor no registrado' : 'Issuer not recorded');
    final issuedByTooltip = [
      isEs ? 'Emitida por $issuedByValue' : 'Issued by $issuedByValue',
      if (issuedAtLabel != null) issuedAtLabel,
    ].join(' · ');

    final deliveryIcon = switch (normalizedDeliveryStatus) {
      'sent' => Icons.mark_email_read_outlined,
      'failed' => Icons.error_outline,
      _ => Icons.mark_email_unread_outlined,
    };
    final statusIconColor =
        isIssued ? cs.primary : cs.onSurface.withValues(alpha: 0.45);
    final linkIconColor =
        isLinked ? cs.tertiary : cs.onSurface.withValues(alpha: 0.45);
    final backendLinkStatusLabel =
        (widget.invoice.linkStatusLabel ?? '').trim();
    final linkTooltip = backendLinkStatusLabel.isNotEmpty
        ? backendLinkStatusLabel
        : (isLinked
            ? l.statementsInvoiceAlreadyLinkedBadge
            : l.statementsUnlinked);
    final effectiveDeliveryColor = switch (normalizedDeliveryStatus) {
      'sent' => cs.primary,
      'failed' => cs.error,
      _ => cs.onSurface.withValues(alpha: 0.45),
    };
    final deliveryTooltip = [
      delivery.labelEs,
      if (sentAtLabel != null) sentAtLabel,
      if (normalizedDeliveryStatus == 'sent') channelLabel,
    ].join(' · ');

    final isSelected = widget.selected;
    final isActive = isSelected || _hovered;
    final warning = widget.warning;
    final monthWarning = widget.monthWarning;
    final amber = isLight ? const Color(0xFF9A5B00) : const Color(0xFFFFC247);
    final amberBg = isLight ? const Color(0xFFFFF4D6) : const Color(0xFF5A3600);

    // Subtotal/IVA tooltip string
    String? breakdownTooltip;
    if (_subtotal != null || _taxTotal != null) {
      final parts = <String>[];
      if (_subtotal != null) parts.add('Sub: ${money.format(_subtotal)}');
      if (hasDiscount) {
        parts.add('$discountLabel: -${money.format(effectiveDiscount)}');
      }
      if (_taxTotal != null) parts.add('IVA: ${money.format(_taxTotal)}');
      breakdownTooltip = parts.join('  ·  ');
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: warning
              ? cs.errorContainer.withValues(alpha: 0.14)
              : monthWarning
                  ? amberBg.withValues(alpha: isLight ? 0.72 : 0.22)
                  : isSelected
                      ? cs.primaryContainer.withValues(alpha: 0.4)
                      : isLight
                          ? Colors.white
                          : _hovered
                              ? cs.surfaceContainerHighest
                                  .withValues(alpha: 0.5)
                              : cs.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: warning
                ? cs.error.withValues(alpha: 0.38)
                : monthWarning
                    ? amber.withValues(alpha: 0.54)
                    : isSelected
                        ? cs.primary.withValues(alpha: 0.65)
                        : _hovered
                            ? cs.outlineVariant.withValues(alpha: 0.65)
                            : cs.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isActive ? 0.06 : 0.035),
                    blurRadius: isActive ? 16 : 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Icon box ─────────────────────────────────────────────────
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: warning
                        ? cs.errorContainer.withValues(alpha: 0.5)
                        : monthWarning
                            ? amberBg.withValues(alpha: isLight ? 0.92 : 0.35)
                            : isIssued
                                ? cs.primary.withValues(alpha: 0.10)
                                : cs.surfaceContainerHighest
                                    .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: warning
                          ? cs.error.withValues(alpha: 0.3)
                          : monthWarning
                              ? amber.withValues(alpha: 0.34)
                              : isIssued
                                  ? cs.primary.withValues(alpha: 0.18)
                                  : cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    warning
                        ? Icons.warning_amber_rounded
                        : monthWarning
                            ? Icons.calendar_month_outlined
                            : isIssued
                                ? Icons.receipt_long_rounded
                                : Icons.receipt_long_outlined,
                    size: 16,
                    color: warning
                        ? cs.error
                        : monthWarning
                            ? amber
                            : isIssued
                                ? cs.primary.withValues(alpha: 0.85)
                                : cs.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(width: 10),

                // ── Main content (2 lines) ────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─ Line 1: client name + badges ──────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.client.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (warning &&
                                    (widget.warningLabel?.trim().isNotEmpty ??
                                        false)) ...[
                                  const SizedBox(width: 5),
                                  _InlinePill(
                                    label: widget.warningLabel!,
                                    color: cs.error,
                                    bg: cs.errorContainer
                                        .withValues(alpha: 0.35),
                                  ),
                                ],
                                if (showInvoiceType) ...[
                                  const SizedBox(width: 5),
                                  _InlinePill(
                                    label: invoiceType == 'advance'
                                        ? (isEs ? 'Anticipo' : 'Advance')
                                        : 'Final',
                                    color: cs.primary,
                                    bg: cs.primary.withValues(alpha: 0.10),
                                  ),
                                ],
                                if (monthWarning &&
                                    (widget.monthWarningLabel
                                            ?.trim()
                                            .isNotEmpty ??
                                        false)) ...[
                                  const SizedBox(width: 5),
                                  Tooltip(
                                    message: widget.monthWarningTooltip ??
                                        widget.monthWarningLabel!,
                                    child: _InlinePill(
                                      label: widget.monthWarningLabel!,
                                      color: amber,
                                      bg: amberBg.withValues(
                                        alpha: isLight ? 0.86 : 0.42,
                                      ),
                                      icon: Icons.warning_amber_rounded,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (totalLabel.isNotEmpty)
                            Tooltip(
                              message: breakdownTooltip ?? '',
                              child: Text(
                                totalLabel,
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color:
                                      hasDiscount ? cs.tertiary : cs.onSurface,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // ─ Line 2: invoice number + date + status + actions ──────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Invoice number + date + line count
                          Expanded(
                            child: Text(
                              [
                                widget.invoice.invoiceNumber,
                                if (_lineCount != null || _loadingMeta)
                                  '${l.invoiceLinesTitle}: $linesCountLabel',
                                if (dateLabel.isNotEmpty) dateLabel,
                              ].join('  ·  '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                fontSize: 11,
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Status pill
                          _StatusPill(
                            isIssued: isIssued,
                            isLinked: isLinked,
                            deliveryIcon: deliveryIcon,
                            statusIconColor: statusIconColor,
                            linkIconColor: linkIconColor,
                            deliveryColor: effectiveDeliveryColor,
                            statusTooltip: isIssued
                                ? '${l.statusIssued}\n$issuedByTooltip'
                                : l.statusDraft,
                            linkTooltip: linkTooltip,
                            deliveryTooltip: deliveryTooltip,
                          ),
                          const SizedBox(width: 6),

                          // Action buttons
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 130),
                            opacity: isActive ? 1.0 : 0.45,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ActionBtn(
                                  icon: _detailsExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  tooltip: _detailsExpanded
                                      ? (isEs
                                          ? 'Ocultar detalles'
                                          : 'Hide details')
                                      : (isEs
                                          ? 'Ver detalles'
                                          : 'Show details'),
                                  color: cs.onSurfaceVariant,
                                  onTap: () => setState(
                                    () => _detailsExpanded = !_detailsExpanded,
                                  ),
                                ),
                                const SizedBox(width: _actionIconGap),
                                _ActionBtn(
                                  icon: Icons.visibility_outlined,
                                  tooltip: isEs ? 'Vista previa' : 'Preview',
                                  color: cs.primary,
                                  onTap: widget.onPreview ?? widget.onTap,
                                ),
                                if (widget.onEdit != null) ...[
                                  const SizedBox(width: _actionIconGap),
                                  _ActionBtn(
                                    icon: Icons.edit_outlined,
                                    tooltip: l.edit,
                                    color: cs.primary,
                                    onTap: widget.onEdit,
                                  ),
                                ],
                                if (widget.onIssue != null) ...[
                                  const SizedBox(width: _actionIconGap),
                                  _ActionBtn(
                                    icon: Icons.publish_outlined,
                                    tooltip: l.invoiceIssueCta,
                                    color: cs.tertiary,
                                    onTap: widget.onIssue,
                                  ),
                                ],
                                if (widget.onInspectRecurrence != null) ...[
                                  const SizedBox(width: _actionIconGap),
                                  _ActionBtn(
                                    icon: Icons.rule_folder_outlined,
                                    tooltip:
                                        isEs ? 'Ver recurrencia' : 'Recurrence',
                                    color: cs.secondary,
                                    onTap: widget.onInspectRecurrence,
                                  ),
                                ],
                                if (widget.onDelete != null) ...[
                                  const SizedBox(width: _actionIconGap),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: _actionIconGap),
                                  _ActionBtn(
                                    icon: Icons.delete_outline_rounded,
                                    tooltip: l.delete,
                                    color: cs.error,
                                    onTap: widget.onDelete,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 160),
                        firstCurve: Curves.easeOut,
                        secondCurve: Curves.easeOut,
                        sizeCurve: Curves.easeOut,
                        crossFadeState: _detailsExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.22),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (dateLabel.isNotEmpty)
                                    _DetailChip(
                                      label: 'Fecha',
                                      value: dateLabel,
                                    ),
                                  if (isIssued)
                                    _DetailChip(
                                      label: isEs ? 'Emitida por' : 'Issued by',
                                      value: issuedByValue,
                                    ),
                                  if (isIssued && issuedAtLabel != null)
                                    _DetailChip(
                                      label: isEs ? 'Emisión' : 'Issued at',
                                      value: issuedAtLabel,
                                    ),
                                  _DetailChip(
                                    label: 'Base',
                                    value: _subtotal == null
                                        ? (_loadingMeta ? '…' : '-')
                                        : money.format(_subtotal),
                                  ),
                                  if (hasDiscount)
                                    _DetailChip(
                                      label: discountLabel,
                                      value:
                                          '-${money.format(effectiveDiscount)}',
                                      accentColor: showsAdvanceDeduction
                                          ? cs.tertiary
                                          : cs.error,
                                    ),
                                  _DetailChip(
                                    label: 'IVA',
                                    value: _taxTotal == null
                                        ? (_loadingMeta ? '…' : '-')
                                        : money.format(_taxTotal),
                                  ),
                                  _DetailChip(
                                    label: 'Total',
                                    value: _total == null
                                        ? (_loadingMeta ? '…' : '-')
                                        : money.format(_total),
                                    accentColor: cs.onSurface,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Inline pill badge ──────────────────────────────────────────────────────────

class _InlinePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const _InlinePill({
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status / Link / Delivery pill ─────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;

  const _DetailChip({
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: RichText(
        text: TextSpan(
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: t.bodySmall.copyWith(
                color: accentColor ?? cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isIssued;
  final bool isLinked;
  final IconData deliveryIcon;
  final Color statusIconColor;
  final Color linkIconColor;
  final Color deliveryColor;
  final String statusTooltip;
  final String linkTooltip;
  final String deliveryTooltip;

  const _StatusPill({
    required this.isIssued,
    required this.isLinked,
    required this.deliveryIcon,
    required this.statusIconColor,
    required this.linkIconColor,
    required this.deliveryColor,
    required this.statusTooltip,
    required this.linkTooltip,
    required this.deliveryTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillIcon(
            icon: isIssued ? Icons.task_alt_outlined : Icons.edit_note_outlined,
            color: statusIconColor,
            tooltip: statusTooltip,
          ),
          _PillIcon(
            icon: isLinked ? Icons.link_rounded : Icons.link_off_rounded,
            color: linkIconColor,
            tooltip: linkTooltip,
          ),
          _PillIcon(
            icon: deliveryIcon,
            color: deliveryColor,
            tooltip: deliveryTooltip,
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 12,
            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _PillIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;

  const _PillIcon(
      {required this.icon, required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.16)
                  : widget.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: widget.color.withValues(alpha: _hovered ? 1.0 : 0.75),
            ),
          ),
        ),
      ),
    );
  }
}
