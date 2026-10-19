import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/documents/mobile_document_card.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/invoicing/invoice_lines_api.dart';
import 'package:hexora/services/shared/content_disposition.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/delivery_status_badge.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  final bool mobile;

  /// Hide the client name when the list is already scoped to one client;
  /// the invoice number becomes the row title instead.
  final bool showClient;

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
    this.mobile = false,
    this.showClient = true,
  });

  @override
  State<InvoiceListItem> createState() => _InvoiceListItemState();
}

class _InvoiceListItemState extends State<InvoiceListItem> {
  final _linesApi = InvoiceLinesApi();

  bool _loadingMeta = false;
  bool _downloadingPdf = false;

  Future<void> _downloadPdf() async {
    if (_downloadingPdf) return;
    setState(() => _downloadingPdf = true);
    try {
      final r = await InvoicesApi().downloadPdf(widget.invoice.id);
      final name = widget.invoice.invoiceNumber.trim().isNotEmpty
          ? widget.invoice.invoiceNumber.trim()
          : widget.invoice.id.trim();
      await launchFileDownload(
        r.bodyBytes,
        fileName: downloadFileNameFromHeaders(
          r.headers,
          fallback: name.endsWith('.pdf') ? name : 'invoice-$name.pdf',
        ),
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

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
    if (!mounted || _loadingMeta || widget.mobile) return;
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

  Widget _buildMobileCard(AppLocalizations l, AppTypography t, ColorScheme cs,
      String total, String date) {
    final inv = widget.invoice;
    return MobileDocumentCard(
      title: widget.client.name,
      amount: total,
      metadata:
          [inv.invoiceNumber, date].where((v) => v.isNotEmpty).join(' · '),
      isDraft: inv.isDraft,
      statusLabel: inv.isDraft ? l.statusDraft : l.statusIssued,
      onTap: widget.onTap,
      badges: [
        DeliveryStatusBadge(
          status: inv.deliveryStatus,
          channel: inv.deliveryChannel,
          sentAt: inv.sentAt,
          deliveryError: inv.deliveryError,
          feminine: true,
        ),
      ],
      trailing: widget.onEdit != null || widget.onDelete != null
          ? PopupMenuButton<String>(
              tooltip: l.edit,
              onSelected: (value) {
                if (value == 'edit') widget.onEdit?.call();
                if (value == 'delete') widget.onDelete?.call();
              },
              itemBuilder: (_) => [
                if (widget.onEdit != null)
                  NavigationPopupMenuItem(value: 'edit', child: Text(l.edit)),
                if (widget.onDelete != null)
                  NavigationPopupMenuItem(
                      value: 'delete',
                      child: Text(l.remove, style: TextStyle(color: cs.error))),
              ],
            )
          : null,
    );
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

    if (widget.mobile) {
      return _buildMobileCard(l, t, cs, totalLabel, dateLabel);
    }

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

    final rawStatus = (widget.invoice.status ?? '').trim().toLowerCase();
    final isCancelled = rawStatus.contains('cancel');
    final isRectified = rawStatus.contains('rectif');
    final documentStatusLabel = isCancelled
        ? (isEs ? 'Anulada' : 'Cancelled')
        : isRectified
            ? (isEs ? 'Rectificativa' : 'Rectified')
            : isIssued
                ? l.statusIssued
                : l.statusDraft;
    final documentStatus = isCancelled
        ? HexoraDocumentStatus.cancelled
        : isRectified
            ? HexoraDocumentStatus.rectified
            : isIssued
                ? HexoraDocumentStatus.issued
                : HexoraDocumentStatus.draft;
    final backendLinkStatusLabel =
        (widget.invoice.linkStatusLabel ?? '').trim();
    final linkTooltip = backendLinkStatusLabel.isNotEmpty
        ? backendLinkStatusLabel
        : (isLinked
            ? (isEs
                ? 'Conciliada con un movimiento bancario'
                : 'Reconciled with a bank transaction')
            : (isEs
                ? 'Sin conciliar con movimientos bancarios'
                : 'Not reconciled with a bank transaction'));

    final warning = widget.warning;
    final monthWarning = widget.monthWarning;
    final amber = isLight ? const Color(0xFF9A5B00) : const Color(0xFFFFC247);

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

    String warningText(String? text) => (text ?? '').trim().isNotEmpty
        ? text!.trim()
        : (isEs ? 'Requiere atención' : 'Requires attention');
    final numberLabel = widget.invoice.displayNumber(draftLabel: l.statusDraft);
    final paymentStatus =
        (widget.invoice.paymentStatus ?? '').trim().toLowerCase();
    final paymentLabel = switch (paymentStatus) {
      'paid' => isEs ? 'Pago: cobrada' : 'Payment: paid',
      'partial' => isEs ? 'Pago: parcialmente cobrada' : 'Payment: partial',
      'overdue' => isEs ? 'Pago: vencida' : 'Payment: overdue',
      'unpaid' => isEs ? 'Pago: pendiente' : 'Payment: pending',
      _ => null,
    };
    final secondaryStates = [
      if (paymentLabel != null) paymentLabel,
      '${isEs ? 'Entrega' : 'Delivery'}: ${deliveryStatusLabel(widget.invoice.deliveryStatus, feminine: true)}',
      linkTooltip,
      if (showInvoiceType)
        invoiceType == 'advance'
            ? (isEs ? 'Factura de anticipo' : 'Advance invoice')
            : (isEs ? 'Factura final' : 'Final invoice'),
    ];
    final warningTooltip = [
      if (warning) warningText(widget.warningLabel),
      if (monthWarning)
        warningText(widget.monthWarningTooltip ?? widget.monthWarningLabel),
    ].join('\n');
    return CompactDocumentRow(
      title: widget.showClient ? widget.client.name : numberLabel,
      titleTrailing: warningTooltip.isEmpty
          ? null
          : Tooltip(
              message: warningTooltip,
              child: Icon(Icons.warning_amber_rounded,
                  size: 16, color: warning ? cs.error : amber),
            ),
      metadata: [
        if (widget.showClient) numberLabel,
        if (dateLabel.isNotEmpty) dateLabel
      ].join(' · '),
      amount: totalLabel,
      selected: widget.selected,
      onTap: widget.onTap,
      previewLabel: isEs ? 'Vista previa' : 'Preview',
      quickActionSlots: 2,
      quickActions: [
        if (widget.onEdit != null)
          CompactDocumentQuickAction(
            icon: Icons.edit_outlined,
            tooltip: l.edit,
            onPressed: widget.onEdit,
          ),
        CompactDocumentQuickAction(
          icon: Icons.download_rounded,
          tooltip: isEs ? 'Descargar PDF' : 'Download PDF',
          busy: _downloadingPdf,
          onPressed: _downloadPdf,
        ),
      ],
      status: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Tooltip(
            message: isIssued
                ? '$documentStatusLabel\n$issuedByTooltip'
                : documentStatusLabel,
            child: HexoraStatusBadge.document(
              context,
              status: documentStatus,
              label: documentStatusLabel,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: secondaryStates.join('\n'),
          child: Icon(Icons.info_outline_rounded,
              size: 16, color: cs.onSurfaceVariant),
        ),
      ]),
      actions: [
        CompactDocumentAction(
            _detailsExpanded
                ? (isEs ? 'Ocultar detalles' : 'Hide details')
                : (isEs ? 'Ver detalles' : 'Show details'),
            () => setState(() => _detailsExpanded = !_detailsExpanded)),
        if (widget.onPreview != null)
          CompactDocumentAction(
              isEs ? 'Vista previa' : 'Preview', widget.onPreview),
        if (widget.onIssue != null)
          CompactDocumentAction(l.invoiceIssueCta, widget.onIssue),
        if (widget.onInspectRecurrence != null)
          CompactDocumentAction(isEs ? 'Ver recurrencia' : 'Recurrence',
              widget.onInspectRecurrence),
        if (widget.onDelete != null)
          CompactDocumentAction(l.delete, widget.onDelete, destructive: true),
      ],
      details: !_detailsExpanded
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                  [
                    '${l.invoiceLinesTitle}: $linesCountLabel',
                    if (dateLabel.isNotEmpty) dateLabel,
                    if (isIssued) issuedByTooltip,
                    if (showInvoiceType) invoiceType,
                    if (breakdownTooltip != null) breakdownTooltip,
                    linkTooltip,
                    if (widget.warningLabel != null) widget.warningLabel!,
                    if (widget.monthWarningTooltip != null)
                      widget.monthWarningTooltip!,
                  ].join(' · '),
                  style: t.bodySmall)),
    );
  }
}
