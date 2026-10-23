import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'dart:convert';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/emails/email_api.dart';
import '../invoice_email_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/models/invoice/client_billing.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/invoice/invoice_line.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/invoicing/invoice_lines_api.dart';
import 'package:hexora/services/shared/content_disposition.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_billing_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_dates.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_header.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_history_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_lines.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_party.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_payment_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/utils/invoice_delivery_utils.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/delivery_status_badge.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

part 'invoice_detail_sheet_logic_mixin.dart';

String _truncateId(String id) =>
    id.length <= 12 ? id : '${id.substring(0, 8)}…';

class InvoiceDetailSheet extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final BillingProfile? billingProfile;
  final Group group;
  final ValueChanged<String>? onOpenRecurringSeries;
  final VoidCallback? onInvoiceChanged;
  final VoidCallback? onClose;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  final bool fullPage;
  final VoidCallback? onExpand;
  final bool isExpanded;

  const InvoiceDetailSheet({
    super.key,
    this.fullPage = false,
    required this.invoice,
    required this.client,
    required this.billingProfile,
    required this.group,
    this.onOpenRecurringSeries,
    this.onInvoiceChanged,
    this.onClose,
    this.onPrevious,
    this.onNext,
    this.onExpand,
    this.isExpanded = false,
  });

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet>
    with InvoiceDetailSheetLogic {
  bool _previewMenuOpen = false;
  int _inlineTabIndex = 0;

  String get _pdfLink {
    final url = _invoice.pdfUrl?.trim();
    return url != null && url.isNotEmpty
        ? url
        : '${ApiConstants.baseUrl}/invoices/${_invoice.id}/pdf';
  }

  Future<void> _copyPdfLink() async {
    await Clipboard.setData(ClipboardData(text: _pdfLink));
    if (!mounted) return;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isEs ? 'Enlace PDF copiado' : 'PDF link copied'),
    ));
  }

  Future<void> _openSendInvoice({required bool canSend}) async {
    if (!canSend) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SendInvoiceSheet(
        invoice: _invoice,
        client: widget.client,
        emailApi: EmailApi(),
        pdfLink: _pdfLink,
        onSent: () async {
          if (!mounted) return;
          await _loadInvoiceDetail();
          if (!mounted) return;
          await _loadInvoiceHistory();
          if (mounted) await _notifyInvoiceChanged();
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetail();
    _lines = widget.invoice.lines;
    _fetchLines();
    if (!widget.fullPage) _loadInlinePdfPreview();
    _loadInvoiceHistory();
  }

  // ── Computed helpers ────────────────────────────────────────────────────────

  String _resolveStatus(String status) {
    final s = status.toLowerCase();
    final l = AppLocalizations.of(context)!;
    if (s.contains('draft')) return l.invoiceStatusDraft;
    if (s.contains('sent') || s.contains('issued')) return l.invoiceStatusSent;
    if (s.contains('paid')) return l.invoiceStatusPaid;
    if (s.contains('overdue')) return l.invoiceStatusOverdue;
    if (s.contains('cancel')) return l.invoiceStatusCancelled;
    return l.invoiceStatusUnknown;
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('draft')) return Icons.edit_note_outlined;
    if (s.contains('sent') || s.contains('issued')) {
      return Icons.task_alt_outlined;
    }
    if (s.contains('paid')) return Icons.paid_outlined;
    if (s.contains('overdue')) return Icons.warning_amber_rounded;
    if (s.contains('cancel')) return Icons.cancel_outlined;
    return Icons.help_outline_rounded;
  }

  Color _statusColor(ColorScheme cs, String status) {
    final s = status.toLowerCase();
    if (s.contains('draft')) return cs.tertiary;
    if (s.contains('sent') || s.contains('issued')) return cs.primary;
    if (s.contains('paid')) return cs.secondary;
    if (s.contains('overdue')) return cs.error;
    return cs.onSurfaceVariant;
  }

  // ── Details dialog ──────────────────────────────────────────────────────────

  void _openDetailsDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .4,
        maxChildSize: .96,
        builder: (_, scrollCtrl) =>
            _buildDetailsContent(scrollCtrl: scrollCtrl),
      ),
    );
  }

  Widget _buildDetailsContent({ScrollController? scrollCtrl}) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final invoice = _invoice;
    final clientBilling = invoice.clientSnapshot ?? widget.client.billing;
    final issuer = invoice.issuerSnapshot ?? widget.billingProfile;
    final billingName = _resolveBillingName(invoice, clientBilling);
    final billingEntity =
        (invoice.entityType ?? widget.client.entityType ?? '').trim();
    final billingStreet = _resolveAddressField(
        invoice.addressStreet, clientBilling?.addressStreet);
    final billingCity =
        _resolveAddressField(invoice.addressCity, clientBilling?.addressCity);
    final billingPostal = _resolveAddressField(
        invoice.addressPostalCode, clientBilling?.addressPostalCode);
    final billingProvince = _resolveAddressField(
        invoice.addressProvince, clientBilling?.addressProvince);
    final billingCountry = _resolveAddressField(
        invoice.addressCountry, clientBilling?.addressCountry);
    final showBillingCard = [
      invoice.billingName,
      invoice.entityType,
      invoice.addressStreet,
      invoice.addressCity,
      invoice.addressPostalCode,
      invoice.addressProvince,
      invoice.addressCountry,
    ].any((v) => (v ?? '').trim().isNotEmpty);
    final history = _invoiceHistory.isNotEmpty
        ? _invoiceHistory
        : invoice.updateHistory.map((entry) => entry.toJson()).toList();
    final deliveryStatus = normalizeDeliveryStatus(invoice.deliveryStatus);
    final canChangeDelivery =
        (invoice.status ?? '').toLowerCase().contains('issue');
    final sentAtLabel = invoice.sentAt == null
        ? '-'
        : DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(invoice.sentAt!.toLocal());
    final channelLabel = invoiceDeliveryChannelLabelEs(invoice.deliveryChannel);
    final settlement = invoice.finalSettlement;
    final showFinalSettlement =
        (invoice.invoiceType ?? '').toLowerCase() == 'final' &&
            settlement != null;
    final moneyFormat =
        NumberFormat.currency(locale: l.localeName, symbol: 'EUR ');
    final isEs = l.localeName.toLowerCase().startsWith('es');

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        if (widget.fullPage) ...[
          OutlinedButton.icon(
            onPressed: _previewing ? null : _previewPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l.invoicePreviewCta),
          ),
          const SizedBox(height: 12),
        ],
        // Sheet title
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        size: 18, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEs ? 'Detalles de factura' : 'Invoice details',
                          style: AppTypography.of(context).bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                        ),
                        Text(
                          invoice.invoiceNumber.trim().isEmpty
                              ? (isEs ? 'Factura' : 'Invoice')
                              : invoice.invoiceNumber.trim(),
                          style: AppTypography.of(context).bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(cs, (invoice.status ?? ''))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _statusColor(cs, (invoice.status ?? ''))
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(invoice.status ?? ''),
                          size: 11,
                          color: _statusColor(cs, invoice.status ?? ''),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _resolveStatus(invoice.status ?? ''),
                          style: AppTypography.of(context).bodySmall.copyWith(
                                color: _statusColor(cs, invoice.status ?? ''),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Final settlement
        if (showFinalSettlement) ...[
          _DetailSection(
            icon: Icons.account_balance_outlined,
            iconColor: cs.secondary,
            title: isEs ? 'Liquidación final' : 'Final settlement',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((settlement.advanceInvoiceNumber ?? '').trim().isNotEmpty)
                  _DetailRow(
                    label: isEs ? 'Factura anticipo' : 'Advance invoice',
                    value: settlement.advanceInvoiceNumber ?? '',
                  ),
                if (settlement.deductedBase != null)
                  _DetailRow(
                    label: isEs ? 'Base deducida' : 'Deducted base',
                    value: moneyFormat.format(settlement.deductedBase),
                  ),
                if (settlement.deductedTax != null)
                  _DetailRow(
                    label: isEs ? 'IVA deducido' : 'Deducted tax',
                    value: moneyFormat.format(settlement.deductedTax),
                  ),
                if (settlement.deductedTotal != null)
                  _DetailRow(
                    label: isEs ? 'Total deducido' : 'Deducted total',
                    value: moneyFormat.format(settlement.deductedTotal),
                    bold: true,
                  ),
                if (settlement.remainingTotal != null)
                  _DetailRow(
                    label: isEs ? 'Total restante' : 'Remaining total',
                    value: moneyFormat.format(settlement.remainingTotal),
                    bold: true,
                    accent: cs.primary,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Parties
        InvoiceDetailParty(
          issuer: issuer,
          clientBilling: clientBilling,
        ),

        // Billing card
        if (showBillingCard) ...[
          const SizedBox(height: 12),
          InvoiceDetailBillingCard(
            title: l.invoiceBillingNameTitle,
            canEdit: !(invoice.status ?? '').toLowerCase().contains('draft'),
            saving: _savingBillingName,
            onEdit: () => _editBillingDetails(invoice, clientBilling),
            billingName: billingName,
            billingEntity: billingEntity,
            billingStreet: billingStreet,
            billingCity: billingCity,
            billingPostal: billingPostal,
            billingProvince: billingProvince,
            billingCountry: billingCountry,
          ),
        ],

        // Dates
        const SizedBox(height: 12),
        InvoiceDetailDates(
          invoice: invoice,
          locale: l.localeName,
          isEs: isEs,
        ),

        const SizedBox(height: 12),
        InvoicePaymentEditor(
          invoice: invoice,
          onSave: _updateInvoicePayment,
        ),

        // Delivery status
        const SizedBox(height: 12),
        _DeliverySection(
          invoice: invoice,
          deliveryStatus: deliveryStatus,
          sentAtLabel: sentAtLabel,
          channelLabel: channelLabel,
          canChangeDelivery: canChangeDelivery,
          updatingDelivery: _updatingDelivery,
          onMarkSent: _markInvoiceSent,
          onMarkUnsent: _markInvoiceUnsent,
        ),

        // History
        const SizedBox(height: 12),
        InvoiceDetailHistoryCard(
          title: l.invoiceChangeHistoryTitle,
          history: history,
          localeName: l.localeName,
          currency: invoice.currency ?? 'EUR',
          loading: _historyLoading,
          error: _historyError,
          onRetry: _loadInvoiceHistory,
        ),

        // Lines
        const SizedBox(height: 12),
        InvoiceDetailLines(
          loading: _loading,
          error: _error,
          lines: _lines,
          onRefresh: _fetchLines,
          subtotal: _invoice.subtotal,
          taxTotal: _invoice.taxTotal,
          total: _invoice.total,
          discountAmount: _invoice.discountAmount,
          discountPercent: _invoice.discountPercent,
        ),
        if (widget.fullPage) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _downloadingPdf ? null : _downloadPdf,
              icon: const Icon(Icons.download_outlined, size: 20),
              label: Text('${l.download} PDF'),
            ),
          ),
        ],
      ],
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.fullPage) return _buildDetailsContent();
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final invoice = _invoice;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final status = (invoice.status ?? '').toLowerCase();
    final isLinked = invoice.isLinkedResolved;
    final linkedEntriesCount = invoice.linkedEntriesCountSafe;
    final hasRecurrence = invoice.recurringSeriesId?.trim().isNotEmpty == true;
    final recurrenceLabel =
        '${l.createdByLabel} ${l.invoiceRecurringLabel.toLowerCase()}';
    final occurrenceLabel = invoice.occurrenceDate == null
        ? null
        : DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(invoice.occurrenceDate!);
    final issueDate = invoice.issueDate ?? invoice.registeredAt;
    final issueDateLabel = issueDate == null ||
            (invoice.status ?? '').trim().toLowerCase() != 'issued'
        ? ''
        : '${isEs ? 'Emitida el' : 'Issued'} ${DateFormat.yMMMd(l.localeName).format(issueDate.toLocal())}';

    final headerMenu = PopupMenuButton<String>(
      tooltip: isEs ? 'Más acciones' : 'More actions',
      position: PopupMenuPosition.under,
      onOpened: () => setState(() => _previewMenuOpen = true),
      onCanceled: () => setState(() => _previewMenuOpen = false),
      onSelected: (value) {
        setState(() => _previewMenuOpen = false);
        switch (value) {
          case 'preview':
            _previewPdf();
          case 'copy':
            _copyPdfLink();
          case 'recurrence':
            widget.onOpenRecurringSeries?.call(invoice.recurringSeriesId!);
        }
      },
      itemBuilder: (_) => [
        NavigationPopupMenuItem(
          value: 'preview',
          enabled: !_previewing,
          child: ListTile(
            leading: const Icon(Icons.open_in_full_rounded),
            title: Text(l.invoicePreviewCta),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        NavigationPopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: Text(isEs ? 'Copiar enlace PDF' : 'Copy PDF link'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (hasRecurrence)
          NavigationPopupMenuItem(
            value: 'recurrence',
            enabled: widget.onOpenRecurringSeries != null,
            child: ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: Text(recurrenceLabel),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
      style: IconButton.styleFrom(
        fixedSize: const Size(32, 32),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.more_horiz_rounded, size: 19),
    );

    return ColoredBox(
      color: Theme.of(context).canvasColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.85;

          return SizedBox(
            height: availableH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                InvoiceDetailHeader(
                  clientName: widget.client.name,
                  invoiceNumber:
                      invoice.displayNumber(draftLabel: l.statusDraft),
                  statusLabel: _resolveStatus(status),
                  statusColor: _statusColor(cs, status),
                  statusIcon: _statusIcon(status),
                  issueDateLabel: issueDateLabel,
                  invoiceType: invoice.invoiceType,
                  moreActions: headerMenu,
                  onPrevious: widget.onPrevious,
                  onNext: widget.onNext,
                  onClose: widget.onClose,
                  onExpand: widget.onExpand,
                  isExpanded: widget.isExpanded,
                ),
                _InvoiceDetailTabs(
                  selectedIndex: _inlineTabIndex,
                  isEs: isEs,
                  onSelected: (index) =>
                      setState(() => _inlineTabIndex = index),
                ),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: .45),
                ),

                // ── PDF Preview ──────────────────────────────────────────────
                Expanded(
                  child: _buildInlineTabContent(
                    cs,
                    l,
                    selectedIndex: _inlineTabIndex,
                    isEs: isEs,
                  ),
                ),

                // ── Footer bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: SafeArea(
                    top: false,
                    child: _buildFooterBar(
                      context,
                      cs,
                      l,
                      isEs: isEs,
                      isLinked: isLinked,
                      linkedEntriesCount: linkedEntriesCount,
                      hasRecurrence: hasRecurrence,
                      recurrenceLabel: recurrenceLabel,
                      occurrenceLabel: occurrenceLabel,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── PDF area widget ─────────────────────────────────────────────────────────

  Widget _buildInlineTabContent(
    ColorScheme cs,
    AppLocalizations l, {
    required int selectedIndex,
    required bool isEs,
  }) {
    if (selectedIndex == 1) return _buildDetailsContent();
    if (selectedIndex == 2) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          InvoiceDetailLines(
            loading: _loading,
            error: _error,
            lines: _lines,
            onRefresh: _fetchLines,
            subtotal: _invoice.subtotal,
            taxTotal: _invoice.taxTotal,
            total: _invoice.total,
            discountAmount: _invoice.discountAmount,
            discountPercent: _invoice.discountPercent,
          ),
        ],
      );
    }
    if (selectedIndex == 3) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          InvoiceDetailHistoryCard(
            title: l.invoiceChangeHistoryTitle,
            history: _invoiceHistory,
            localeName: l.localeName,
            currency: _invoice.currency ?? 'EUR',
            loading: _historyLoading,
            error: _historyError,
            onRetry: _loadInvoiceHistory,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: .4),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                isEs ? 'Vista previa PDF' : 'PDF preview',
                style: AppTypography.of(context).bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _downloadingPdf ? null : _downloadPdf,
                tooltip: l.download,
                icon: _downloadingPdf
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                style: IconButton.styleFrom(
                  fixedSize: const Size(32, 32),
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _previewing ? null : _previewPdf,
                tooltip: l.invoicePreviewCta,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  fixedSize: const Size(32, 32),
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _buildPdfArea(cs, l),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfArea(ColorScheme cs, AppLocalizations l) {
    if (_inlinePdfLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.localeName.startsWith('es')
                  ? 'Generando vista previa…'
                  : 'Generating preview…',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_inlinePdfBytes != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final h =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;
          return PdfInlinePreview(
            bytes: _inlinePdfBytes!,
            height: h,
            showToolbar: false,
            interactive: !_previewMenuOpen,
          );
        },
      );
    }

    if ((_inlinePdfError ?? '').trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: cs.error,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.localeName.startsWith('es')
                    ? 'Error al cargar el PDF'
                    : 'Failed to load PDF',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _inlinePdfError!,
                style: TextStyle(
                  color: cs.error,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadInlinePdfPreview,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l.tryAgain),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No PDF yet (shouldn't normally reach here)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 40,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            l.localeName.startsWith('es') ? 'Sin vista previa' : 'No preview',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer bar ──────────────────────────────────────────────────────────────

  Widget _buildFooterBar(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l, {
    required bool isEs,
    required bool isLinked,
    required int linkedEntriesCount,
    required bool hasRecurrence,
    required String recurrenceLabel,
    required String? occurrenceLabel,
  }) {
    final currentUserId = context.watch<UserDomain?>()?.user?.id;
    final role =
        currentUserId == null ? null : widget.group.userRoles[currentUserId];
    final canSend = role == 'owner' || role == 'co-admin';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final buttonStyle = OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
        Widget actionLabel(IconData icon, String label) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Flexible(child: Text(label))
            ],
          );
        }

        final details = FilledButton.icon(
          onPressed: () => _openDetailsDialog(context),
          icon: const Icon(Icons.receipt_long_outlined, size: 15),
          label: Text(isEs ? 'Ver detalles' : 'Details'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        final secondary = Row(
          children: [
            Expanded(
              child: Tooltip(
                message: canSend
                    ? l.invoiceSendCta
                    : (isEs
                        ? 'Solo propietarios y coadministradores pueden enviar facturas'
                        : 'Only owners and co-admins can send invoices'),
                child: OutlinedButton(
                  onPressed:
                      canSend ? () => _openSendInvoice(canSend: canSend) : null,
                  style: buttonStyle,
                  child: actionLabel(
                      Icons.mail_outline_rounded, isEs ? 'Enviar' : 'Send'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _downloadingPdf ? null : _downloadPdf,
                style: buttonStyle,
                child: actionLabel(
                  _downloadingPdf
                      ? Icons.hourglass_empty_rounded
                      : Icons.download_outlined,
                  l.download,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: isEs ? 'Más acciones' : 'More actions',
              onOpened: () => setState(() => _previewMenuOpen = true),
              onCanceled: () => setState(() => _previewMenuOpen = false),
              icon: const Icon(Icons.more_horiz_rounded),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: cs.outlineVariant),
              ),
              onSelected: (value) {
                setState(() => _previewMenuOpen = false);
                switch (value) {
                  case 'preview':
                    _previewPdf();
                  case 'copy':
                    _copyPdfLink();
                  case 'recurrence':
                    widget.onOpenRecurringSeries
                        ?.call(_invoice.recurringSeriesId!);
                }
              },
              itemBuilder: (_) => [
                NavigationPopupMenuItem(
                  value: 'preview',
                  enabled: !_previewing,
                  child: ListTile(
                    leading: const Icon(Icons.open_in_full_rounded),
                    title: Text(l.invoicePreviewCta),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                NavigationPopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(isEs ? 'Copiar enlace PDF' : 'Copy PDF link'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (hasRecurrence)
                  NavigationPopupMenuItem(
                    value: 'recurrence',
                    enabled: widget.onOpenRecurringSeries != null,
                    child: ListTile(
                      leading: const Icon(Icons.repeat_rounded),
                      title: Text(recurrenceLabel),
                      subtitle: occurrenceLabel == null
                          ? null
                          : Text(occurrenceLabel),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                NavigationPopupMenuItem<String>(
                  enabled: false,
                  child: ListTile(
                    leading: Icon(
                        isLinked ? Icons.link_rounded : Icons.link_off_rounded),
                    title: Text(isLinked
                        ? '${l.statementsInvoiceAlreadyLinkedBadge} ($linkedEntriesCount)'
                        : l.statementsUnlinked),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [details, const SizedBox(height: 8), secondary],
          );
        }
        return Row(
          children: [
            Expanded(flex: 9, child: details),
            const SizedBox(width: 8),
            Expanded(flex: 11, child: secondary),
          ],
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconColor;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = iconColor ?? cs.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.of(context).bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Detail row ─────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? accent;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.of(context).bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: AppTypography.of(context).bodySmall.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: accent ?? cs.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery section (extracted to avoid massive build method) ─────────────────

class _DeliverySection extends StatelessWidget {
  final Invoice invoice;
  final String deliveryStatus;
  final String sentAtLabel;
  final String channelLabel;
  final bool canChangeDelivery;
  final bool updatingDelivery;
  final Future<void> Function({required String channel}) onMarkSent;
  final VoidCallback onMarkUnsent;

  const _DeliverySection({
    required this.invoice,
    required this.deliveryStatus,
    required this.sentAtLabel,
    required this.channelLabel,
    required this.canChangeDelivery,
    required this.updatingDelivery,
    required this.onMarkSent,
    required this.onMarkUnsent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.send_rounded, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Estado de envío',
                  style: AppTypography.of(context).bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                DeliveryStatusBadge(
                  status: invoice.deliveryStatus,
                  channel: invoice.deliveryChannel,
                  sentAt: invoice.sentAt,
                  deliveryError: invoice.deliveryError,
                  feminine: true,
                ),
              ],
            ),
          ),

          // Meta
          if (invoice.sentAt != null ||
              (invoice.deliveryChannel ?? '').trim().isNotEmpty ||
              (invoice.sentBy ?? '').trim().isNotEmpty) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (invoice.sentAt != null)
                    _MetaChip(
                        icon: Icons.schedule_outlined, label: sentAtLabel),
                  if ((invoice.deliveryChannel ?? '').trim().isNotEmpty)
                    _MetaChip(
                      icon: channelLabel.toLowerCase().contains('email')
                          ? Icons.email_outlined
                          : Icons.send_outlined,
                      label: channelLabel,
                    ),
                  if ((invoice.sentBy ?? '').trim().isNotEmpty)
                    _MetaChip(
                      icon: Icons.person_outline,
                      label: _truncateId(invoice.sentBy!.trim()),
                    ),
                ],
              ),
            ),
          ],

          // Error
          if (deliveryStatus == 'failed' &&
              (invoice.deliveryError ?? '').trim().isNotEmpty) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 13, color: cs.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      invoice.deliveryError!.trim(),
                      style: AppTypography.of(context)
                          .bodySmall
                          .copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions
          if (canChangeDelivery) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: PopupMenuButton<String>(
                      tooltip: 'Marcar como enviada',
                      enabled: !updatingDelivery,
                      onSelected: (value) => onMarkSent(channel: value),
                      itemBuilder: (_) => const [
                        NavigationPopupMenuItem(
                            value: 'manual', child: Text('Manual')),
                        NavigationPopupMenuItem(
                            value: 'email', child: Text('Email')),
                        NavigationPopupMenuItem(
                            value: 'whatsapp', child: Text('WhatsApp')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (updatingDelivery)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onSecondaryContainer,
                                ),
                              )
                            else
                              Icon(
                                Icons.mark_email_read_outlined,
                                size: 15,
                                color: cs.onSecondaryContainer,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              'Marcar enviada',
                              style:
                                  AppTypography.of(context).bodySmall.copyWith(
                                        color: cs.onSecondaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down,
                                size: 16, color: cs.onSecondaryContainer),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Tooltip(
                      message: 'Marcar como no enviada',
                      child: OutlinedButton(
                        onPressed: updatingDelivery ? null : onMarkUnsent,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Icon(Icons.mark_email_unread_outlined,
                            size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.of(context)
              .bodySmall
              .copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _InvoiceDetailTabs extends StatelessWidget {
  const _InvoiceDetailTabs({
    required this.selectedIndex,
    required this.isEs,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool isEs;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final labels = isEs
        ? const ['Vista previa', 'Datos', 'Líneas', 'Historial']
        : const ['Preview', 'Details', 'Lines', 'History'];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return Semantics(
            selected: selected,
            button: true,
            label: labels[index],
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: selected ? cs.primary : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  style: t.bodySmall.copyWith(
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
