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
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_public_link_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/utils/invoice_delivery_utils.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/delivery_status_badge.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/navigation/dashboard_sections.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_state.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/shared/widgets/buttons/buttons.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

part 'invoice_detail_sheet_logic_mixin.dart';

class InvoiceDetailSheet extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final BillingProfile? billingProfile;
  final Group group;
  final ValueChanged<String>? onOpenRecurringSeries;
  final VoidCallback? onOpenDeliveryRecord;
  final VoidCallback? onInvoiceChanged;
  final VoidCallback? onEditInvoice;
  final Future<void> Function(Invoice invoice)? onIssueInvoice;
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
    this.onOpenDeliveryRecord,
    this.onInvoiceChanged,
    this.onEditInvoice,
    this.onIssueInvoice,
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
  bool _issuingInvoice = false;

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

  void _openBankTransactions() {
    final dashboard = Provider.of<GroupDashboardState?>(context, listen: false);
    if (dashboard != null) {
      dashboard.openSection(Sections.enableBanking);
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.enableBanking,
      arguments: widget.group,
    );
  }

  void _afterClosingDetails(VoidCallback action, BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
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

  @override
  void didUpdateWidget(covariant InvoiceDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.invoice;
    final current = widget.invoice;
    final differentInvoice = previous.id != current.id;
    final documentChanged = previous.status != current.status ||
        previous.invoiceNumber != current.invoiceNumber ||
        previous.issueDate != current.issueDate;
    final paymentChanged = previous.paymentStatus != current.paymentStatus ||
        previous.paidAmount != current.paidAmount ||
        previous.paidAt != current.paidAt ||
        previous.paymentSource != current.paymentSource;
    if (!differentInvoice && !documentChanged && !paymentChanged) return;
    _currentInvoice = null;
    if (differentInvoice) {
      _lines = current.lines;
      _fetchLines();
      _loadInvoiceHistory();
    }
    _loadInvoiceDetail();
    if (!widget.fullPage) _loadInlinePdfPreview();
  }

  Future<void> _issueSelectedInvoice() async {
    if (_issuingInvoice || !mounted) return;
    final callback = widget.onIssueInvoice;
    final invoice = _invoice;
    if (callback == null || !invoice.isDraft) return;
    setState(() => _issuingInvoice = true);
    try {
      await callback(invoice);
      if (mounted) await _loadInvoiceDetail();
    } finally {
      if (mounted) setState(() => _issuingInvoice = false);
    }
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
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .4,
        maxChildSize: .96,
        builder: (_, scrollCtrl) => _buildDetailsContent(
          scrollCtrl: scrollCtrl,
          onOpenPayments: () =>
              _afterClosingDetails(_openBankTransactions, sheetContext),
          onOpenDelivery: widget.onOpenDeliveryRecord == null
              ? null
              : () => _afterClosingDetails(
                    widget.onOpenDeliveryRecord!,
                    sheetContext,
                  ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent({
    ScrollController? scrollCtrl,
    VoidCallback? onOpenPayments,
    VoidCallback? onOpenDelivery,
  }) {
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
        if ((invoice.status ?? '').toLowerCase() == 'issued' &&
            widget.onEditInvoice != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onEditInvoice,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                  isEs ? 'Modificar factura emitida' : 'Edit issued invoice'),
            ),
          ),
          const SizedBox(height: 4),
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
        _PaymentStatusSection(
          invoice: invoice,
          localeName: l.localeName,
          onOpenPayments: onOpenPayments ?? _openBankTransactions,
        ),
        if ((invoice.status ?? '').toLowerCase() == 'issued') ...[
          const SizedBox(height: 12),
          InvoicePublicLinkCard(invoiceId: invoice.id),
        ],

        // Delivery status
        const SizedBox(height: 12),
        _DeliverySection(
          invoice: invoice,
          deliveryStatus: deliveryStatus,
          sentAtLabel: sentAtLabel,
          channelLabel: channelLabel,
          onOpenDelivery: onOpenDelivery ?? widget.onOpenDeliveryRecord,
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
    // Tab 0 = Resumen
    if (selectedIndex == 0) {
      return _buildResumenTab(cs, l, isEs: isEs);
    }
    // Tab 2 = Historial
    if (selectedIndex == 2) {
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

    // Tab 1 = Vista previa
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

  // ── Resumen tab ──────────────────────────────────────────────────────────────

  Widget _buildResumenTab(ColorScheme cs, AppLocalizations l,
      {required bool isEs}) {
    final invoice = _invoice;
    final t = AppTypography.of(context);
    final money = NumberFormat.currency(locale: l.localeName, symbol: '€ ');
    final status = (invoice.status ?? '').toLowerCase();
    final deliveryStatus = normalizeDeliveryStatus(invoice.deliveryStatus);
    final sentAtLine = invoice.sentAt != null
        ? DateFormat('d MMM y · HH:mm', l.localeName)
            .format(invoice.sentAt!.toLocal())
        : null;
    final channelLabel = invoiceDeliveryChannelLabelEs(invoice.deliveryChannel);

    final issueDate = invoice.issuedAtResolved ?? invoice.registeredAt;
    final issueDateStr = issueDate != null
        ? DateFormat('d MMM y', l.localeName).format(issueDate.toLocal())
        : '-';

    final settlement = invoice.finalSettlement;
    final showFinalSettlement =
        (invoice.invoiceType ?? '').toLowerCase() == 'final' &&
            settlement != null;
    final moneyFormat =
        NumberFormat.currency(locale: l.localeName, symbol: 'EUR ');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── Total + status header ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEs ? 'Total factura' : 'Invoice total',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money.format(invoice.total ?? 0),
                      style: t.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(cs, status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _statusColor(cs, status).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status),
                        size: 12, color: _statusColor(cs, status)),
                    const SizedBox(width: 4),
                    Text(
                      _resolveStatus(status),
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _statusColor(cs, status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Client + Date rows ──
        _SummaryRow(
          icon: Icons.person_outline_rounded,
          label: isEs ? 'Cliente' : 'Client',
          value: widget.client.name,
        ),
        _SummaryRow(
          icon: Icons.calendar_today_rounded,
          label: isEs ? 'Fecha' : 'Date',
          value: issueDateStr,
        ),

        const SizedBox(height: 10),

        // ── Payment section ──
        _PaymentStatusSection(
          invoice: invoice,
          localeName: l.localeName,
          onOpenPayments: invoice.isLinkedResolved ||
                  (invoice.linkedEntryId ?? '').trim().isNotEmpty
              ? _openBankTransactions
              : null,
        ),

        const SizedBox(height: 10),

        // ── Delivery section ──
        _DeliverySection(
          invoice: invoice,
          deliveryStatus: deliveryStatus,
          sentAtLabel: sentAtLine ?? '-',
          channelLabel: channelLabel,
          onOpenDelivery: widget.onOpenDeliveryRecord,
        ),

        // ── Final settlement ──
        if (showFinalSettlement) ...[
          const SizedBox(height: 10),
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
        ],

        const SizedBox(height: 10),

        // ── Invoice lines ──
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
          return Stack(children: [
            PdfInlinePreview(
              bytes: _inlinePdfBytes!,
              height: h,
              showToolbar: false,
              interactive: !_previewMenuOpen,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                child: IconButton(
                  tooltip: l.localeName.startsWith('es')
                      ? 'Actualizar estado y vista previa'
                      : 'Refresh payment status and preview',
                  onPressed: _refreshPaymentAndPreview,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ]);
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
    final status = (_invoice.status ?? '').toLowerCase();
    final showPublicLink = status == 'issued';
    final canIssue = _invoice.isDraft &&
        widget.onIssueInvoice != null &&
        (currentUserId == widget.group.ownerId ||
            role == 'owner' ||
            role == 'admin' ||
            role == 'co-admin');
    final canEditDraft = _invoice.isDraft && widget.onEditInvoice != null;

    final details = HexoraButton(
      onPressed: () => _openDetailsDialog(context),
      icon: Icons.receipt_long_outlined,
      label: isEs ? 'Ver detalles' : 'Details',
      variant: HexoraButtonVariant.secondary,
    );
    final send = HexoraButton(
      onPressed: canSend ? () => _openSendInvoice(canSend: canSend) : null,
      icon: Icons.mail_outline_rounded,
      label: isEs ? 'Enviar' : 'Send',
      variant: HexoraButtonVariant.secondary,
      tooltip: canSend
          ? l.invoiceSendCta
          : (isEs
              ? 'Solo propietarios y coadministradores pueden enviar facturas'
              : 'Only owners and co-admins can send invoices'),
    );
    final edit = HexoraButton(
      key: const ValueKey('invoice-detail-edit-draft-button'),
      onPressed: canEditDraft ? widget.onEditInvoice : null,
      icon: Icons.edit_outlined,
      label: isEs ? 'Editar' : 'Edit',
      variant: HexoraButtonVariant.secondary,
    );
    final overflow = PopupMenuButton<String>(
      tooltip: isEs ? 'Más acciones' : 'More actions',
      onOpened: () => setState(() => _previewMenuOpen = true),
      onCanceled: () => setState(() => _previewMenuOpen = false),
      icon: const Icon(Icons.more_horiz_rounded, size: 18),
      style: IconButton.styleFrom(
        fixedSize: const Size(
            HexoraDimensions.buttonStandard, HexoraDimensions.buttonStandard),
        minimumSize: const Size(
            HexoraDimensions.buttonStandard, HexoraDimensions.buttonStandard),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: cs.outlineVariant),
      ),
      onSelected: (value) {
        setState(() => _previewMenuOpen = false);
        switch (value) {
          case 'download':
            _downloadPdf();
          case 'preview':
            _previewPdf();
          case 'copy':
            _copyPdfLink();
          case 'recurrence':
            widget.onOpenRecurringSeries?.call(_invoice.recurringSeriesId!);
        }
      },
      itemBuilder: (_) => [
        NavigationPopupMenuItem(
          value: 'download',
          enabled: !_downloadingPdf,
          child: ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text('${l.download} PDF'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
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
              subtitle: occurrenceLabel == null ? null : Text(occurrenceLabel),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (showPublicLink)
          NavigationPopupMenuItem(
            value: 'public_link',
            enabled: false,
            child: ListTile(
              leading: const Icon(Icons.qr_code_2_rounded),
              title: Text(isEs ? 'Factura digital' : 'Digital invoice'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        NavigationPopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            leading:
                Icon(isLinked ? Icons.link_rounded : Icons.link_off_rounded),
            title: Text(isLinked
                ? '${l.statementsInvoiceAlreadyLinkedBadge} ($linkedEntriesCount)'
                : l.statementsUnlinked),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    if (_invoice.isDraft) {
      final draftActions = <Widget>[
        if (canIssue)
          HexoraButton(
            key: const ValueKey('invoice-detail-issue-button'),
            onPressed: _issuingInvoice ? null : _issueSelectedInvoice,
            icon: Icons.publish_outlined,
            label: isEs ? 'Emitir' : 'Issue',
            loading: _issuingInvoice,
          ),
        if (canEditDraft) edit,
        details,
        send,
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          if (constraints.maxWidth >= 560) {
            return Row(
              children: [
                for (var index = 0; index < draftActions.length; index++) ...[
                  if (index > 0) const SizedBox(width: gap),
                  Expanded(child: draftActions[index]),
                ],
              ],
            );
          }

          final itemWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final action in draftActions)
                SizedBox(width: itemWidth, child: action),
            ],
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: details),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: send),
        const SizedBox(width: 8),
        overflow,
      ],
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

class _PaymentStatusSection extends StatelessWidget {
  const _PaymentStatusSection({
    required this.invoice,
    required this.localeName,
    this.onOpenPayments,
  });

  final Invoice invoice;
  final String localeName;
  final VoidCallback? onOpenPayments;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = localeName.toLowerCase().startsWith('es');
    final status = (invoice.paymentStatus ?? '').trim().toLowerCase();
    final isPaid = const {'paid', 'pagada', 'pagado'}.contains(status);
    final isPartial =
        const {'partial', 'partially_paid', 'parcial'}.contains(status);
    final color = isPaid
        ? (Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF2E7D32)
            : const Color(0xFF81C784))
        : isPartial
            ? cs.tertiary
            : cs.onSurfaceVariant;
    final label = isPaid
        ? (isEs ? 'Pagada' : 'Paid')
        : isPartial
            ? (isEs ? 'Pago parcial' : 'Partially paid')
            : (isEs ? 'Pendiente' : 'Pending');
    final total = invoice.total?.toDouble();
    final paid =
        invoice.paidAmount?.toDouble() ?? (isPaid && total != null ? total : 0);
    final outstanding = total == null ? null : (total - paid).clamp(0, total);
    final money = NumberFormat.currency(locale: localeName, symbol: '€');
    final paidAt = invoice.paidAt == null
        ? null
        : DateFormat.yMMMd(localeName)
            .add_Hm()
            .format(invoice.paidAt!.toLocal());
    final method = _paymentMethodLabel(invoice.paymentMethod, isEs: isEs);
    final source = _paymentSourceLabel(invoice.paymentSource, isEs: isEs);
    final linkedCount = invoice.linkedEntriesCountSafe;
    final linkedEntryId = (invoice.linkedEntryId ?? '').trim();
    final canOpenPayments =
        onOpenPayments != null && (linkedCount > 0 || linkedEntryId.isNotEmpty);

    return _CompactStatusSection(
      icon: isPaid
          ? Icons.check_circle_outline_rounded
          : isPartial
              ? Icons.timelapse_rounded
              : Icons.schedule_outlined,
      title: isEs ? 'Pago' : 'Payment',
      color: color,
      status: label,
      metadata: [
        _MetaChip(
          icon: Icons.payments_outlined,
          label: '${isEs ? 'Pagado' : 'Paid'}: ${money.format(paid)}',
        ),
        if (outstanding != null)
          _MetaChip(
            icon: Icons.account_balance_wallet_outlined,
            label:
                '${isEs ? 'Pendiente' : 'Outstanding'}: ${money.format(outstanding)}',
          ),
        if (paidAt != null)
          _MetaChip(icon: Icons.event_available_outlined, label: paidAt),
        if (method != null)
          _MetaChip(icon: Icons.credit_card_outlined, label: method),
        if (source != null)
          _MetaChip(icon: Icons.source_outlined, label: source),
      ],
      action: canOpenPayments
          ? HexoraButton(
              onPressed: onOpenPayments,
              icon: Icons.open_in_new_rounded,
              label: isEs ? 'Ver pago' : 'View payment',
              variant: HexoraButtonVariant.ghost,
              size: HexoraButtonSize.compact,
            )
          : null,
    );
  }

  static String? _paymentMethodLabel(String? value, {required bool isEs}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    return switch (raw.toLowerCase()) {
      'transfer' => isEs ? 'Transferencia' : 'Transfer',
      'cash' => isEs ? 'Efectivo' : 'Cash',
      'card' => isEs ? 'Tarjeta' : 'Card',
      'check' => isEs ? 'Cheque' : 'Check',
      'bizum' => 'Bizum',
      _ => raw,
    };
  }

  static String? _paymentSourceLabel(String? value, {required bool isEs}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    return switch (raw.toLowerCase()) {
      'manual' || 'manual_entry' => isEs ? 'Registro manual' : 'Manual entry',
      'bank' ||
      'bank_transaction' ||
      'statement' ||
      'reconciliation' =>
        isEs ? 'Conciliación bancaria' : 'Bank reconciliation',
      _ => raw,
    };
  }
}

class _DeliverySection extends StatelessWidget {
  const _DeliverySection({
    required this.invoice,
    required this.deliveryStatus,
    required this.sentAtLabel,
    required this.channelLabel,
    this.onOpenDelivery,
  });

  final Invoice invoice;
  final String deliveryStatus;
  final String sentAtLabel;
  final String channelLabel;
  final VoidCallback? onOpenDelivery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final delivered = deliveryStatus == 'delivered';
    final sent = deliveryStatus == 'sent';
    final failed = deliveryStatus == 'failed';
    final color = delivered
        ? (Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF2E7D32)
            : const Color(0xFF81C784))
        : sent
            ? cs.primary
            : failed
                ? cs.error
                : cs.onSurfaceVariant;
    final hasDeliveryRecord =
        invoice.sentAt != null || sent || delivered || failed;
    final canOpenDelivery = onOpenDelivery != null && hasDeliveryRecord;

    return _CompactStatusSection(
      icon: delivered
          ? Icons.done_all_rounded
          : sent
              ? Icons.send_rounded
              : failed
                  ? Icons.error_outline_rounded
                  : Icons.mark_email_unread_outlined,
      title: isEs ? 'Envío' : 'Delivery',
      color: color,
      status: deliveryStatusLabel(invoice.deliveryStatus, feminine: true),
      metadata: [
        if (invoice.sentAt != null)
          _MetaChip(icon: Icons.schedule_outlined, label: sentAtLabel),
        if ((invoice.deliveryChannel ?? '').trim().isNotEmpty &&
            channelLabel != '-')
          _MetaChip(
            icon: channelLabel.toLowerCase().contains('email')
                ? Icons.email_outlined
                : Icons.send_outlined,
            label: channelLabel,
          ),
        if (failed && (invoice.deliveryError ?? '').trim().isNotEmpty)
          _MetaChip(
            icon: Icons.error_outline_rounded,
            label: invoice.deliveryError!.trim(),
          ),
      ],
      action: canOpenDelivery
          ? HexoraButton(
              onPressed: onOpenDelivery,
              icon: Icons.open_in_new_rounded,
              label: isEs ? 'Ver envío' : 'View delivery',
              variant: HexoraButtonVariant.ghost,
              size: HexoraButtonSize.compact,
            )
          : null,
    );
  }
}

class _CompactStatusSection extends StatelessWidget {
  const _CompactStatusSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.status,
    required this.metadata,
    this.action,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String status;
  final List<Widget> metadata;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: t.bodySmall.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (metadata.isNotEmpty || action != null) ...[
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackAction = constraints.maxWidth < 420 ||
                    MediaQuery.textScalerOf(context).scale(12) > 17;
                final meta = Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: metadata,
                );
                if (action == null) return meta;
                if (stackAction) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (metadata.isNotEmpty) meta,
                      if (metadata.isNotEmpty) const SizedBox(height: 4),
                      action!,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: meta),
                    const SizedBox(width: 8),
                    action!,
                  ],
                );
              },
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

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
        ? const ['Resumen', 'Vista previa', 'Historial']
        : const ['Summary', 'Preview', 'History'];

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
