import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/emails/email_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_billing_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_footer_actions.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_history_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_lines.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_party.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_email_widgets.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/invoice_delivery_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

part 'invoice_detail_sheet_logic_mixin.dart';

class InvoiceDetailSheet extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final BillingProfile? billingProfile;
  final Group group;
  final ValueChanged<String>? onOpenRecurringSeries;
  final VoidCallback? onInvoiceChanged;

  const InvoiceDetailSheet({
    super.key,
    required this.invoice,
    required this.client,
    required this.billingProfile,
    required this.group,
    this.onOpenRecurringSeries,
    this.onInvoiceChanged,
  });

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet>
    with InvoiceDetailSheetLogic {
  @override
  void initState() {
    super.initState();
    _loadInvoiceDetail();
    _lines = widget.invoice.lines;
    _fetchLines();
    _loadInlinePdfPreview();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final invoice = _invoice;
    final issuer = invoice.issuerSnapshot ?? widget.billingProfile;
    final clientBilling = invoice.clientSnapshot ?? widget.client.billing;
    final billingName = _resolveBillingName(invoice, clientBilling);
    final billingEntity =
        (invoice.entityType ?? widget.client.entityType ?? '').trim();
    final billingStreet = _resolveAddressField(
      invoice.addressStreet,
      clientBilling?.addressStreet,
    );
    final billingCity =
        _resolveAddressField(invoice.addressCity, clientBilling?.addressCity);
    final billingPostal = _resolveAddressField(
      invoice.addressPostalCode,
      clientBilling?.addressPostalCode,
    );
    final billingProvince = _resolveAddressField(
        invoice.addressProvince, clientBilling?.addressProvince);
    final billingCountry = _resolveAddressField(
        invoice.addressCountry, clientBilling?.addressCountry);
    final isLinked = invoice.isLinkedResolved;
    final linkedEntriesCount = invoice.linkedEntriesCountSafe;
    final deliveryData = invoiceDeliveryViewData(invoice.deliveryStatus);
    final deliveryColor = invoiceDeliveryColor(cs, deliveryData.visual);
    final deliveryStatus = normalizeDeliveryStatus(invoice.deliveryStatus);
    final sentAtLabel = invoice.sentAt == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).add_Hm().format(invoice.sentAt!.toLocal());
    final channelLabel = invoiceDeliveryChannelLabelEs(invoice.deliveryChannel);
    final canChangeDelivery = (invoice.status ?? '').toLowerCase().contains('issue');
    final showBillingCard = [
      invoice.billingName,
      invoice.entityType,
      invoice.addressStreet,
      invoice.addressCity,
      invoice.addressPostalCode,
      invoice.addressProvince,
      invoice.addressCountry,
    ].any((v) => (v ?? '').trim().isNotEmpty);
    final history = [...invoice.updateHistory]..sort((a, b) {
        final ad = a.changedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.changedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ColoredBox(
      color: Theme.of(context).canvasColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.8;
          final panelHeight = (maxHeight - 108).clamp(320.0, maxHeight);
          final hasRecurrence =
              invoice.recurringSeriesId?.trim().isNotEmpty == true;
          final recurrenceLabel =
              '${l.createdByLabel} ${l.invoiceRecurringLabel.toLowerCase()}';
          final occurrenceLabel = invoice.occurrenceDate == null
              ? null
              : DateFormat.yMMMd(l.localeName)
                  .add_Hm()
                  .format(invoice.occurrenceDate!);
          final status = (invoice.status ?? '').toLowerCase();
          final statusInfoLabel = status.contains('draft')
              ? l.invoiceStatusDraft
              : (status.contains('sent') || status.contains('issued'))
                  ? l.invoiceStatusSent
                  : status.contains('paid')
                      ? l.invoiceStatusPaid
                      : status.contains('overdue')
                          ? l.invoiceStatusOverdue
                          : status.contains('cancel')
                              ? l.invoiceStatusCancelled
                              : l.invoiceStatusUnknown;
          final statusInfoIcon = status.contains('draft')
              ? Icons.edit_note_outlined
              : (status.contains('sent') || status.contains('issued'))
                  ? Icons.task_alt_outlined
                  : status.contains('paid')
                      ? Icons.paid_outlined
                      : status.contains('overdue')
                          ? Icons.warning_amber_rounded
                          : status.contains('cancel')
                              ? Icons.cancel_outlined
                              : Icons.help_outline_rounded;
          final statusInfoColor = status.contains('draft')
              ? cs.tertiary
              : (status.contains('sent') || status.contains('issued'))
                  ? cs.primary
                  : status.contains('paid')
                      ? cs.secondary
                      : status.contains('overdue')
                          ? cs.error
                          : cs.onSurfaceVariant;

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InvoiceDetailHeader(
                    clientName: widget.client.name,
                    invoiceNumber: invoice.invoiceNumber,
                    hasRecurrence: hasRecurrence,
                    recurrenceLabel: recurrenceLabel,
                    occurrenceLabel: occurrenceLabel,
                    recurrenceButtonLabel: l.invoiceRecurringLabel,
                    onOpenRecurringSeries: widget.onOpenRecurringSeries,
                    recurringSeriesId: invoice.recurringSeriesId,
                    status: invoice.status ?? 'draft',
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: panelHeight,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: 96 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_inlinePdfLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          else if (_inlinePdfBytes != null)
                            PdfInlinePreview(
                              bytes: _inlinePdfBytes!,
                              height: 320,
                            )
                          else if ((_inlinePdfError ?? '').trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cs.error.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_outlined,
                                    color: cs.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _inlinePdfError!,
                                      style: TextStyle(color: cs.error),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l.tryAgain,
                                    onPressed: _loadInlinePdfPreview,
                                    icon: const Icon(Icons.refresh),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          InvoiceDetailParty(
                            issuer: issuer,
                            clientBilling: clientBilling,
                          ),
                          if (showBillingCard) ...[
                            const SizedBox(height: 8),
                            InvoiceDetailBillingCard(
                              title: l.invoiceBillingNameTitle,
                              canEdit: !(invoice.status ?? '')
                                  .toLowerCase()
                                  .contains('draft'),
                              saving: _savingBillingName,
                              onEdit: () =>
                                  _editBillingDetails(invoice, clientBilling),
                              billingName: billingName,
                              billingEntity: billingEntity,
                              billingStreet: billingStreet,
                              billingCity: billingCity,
                              billingPostal: billingPostal,
                              billingProvince: billingProvince,
                              billingCountry: billingCountry,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estado de envio',
                                  style: AppTypography.of(context).bodyMedium.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: deliveryColor.withValues(alpha: 0.6),
                                        ),
                                        color: deliveryColor.withValues(alpha: 0.12),
                                      ),
                                      child: Text(
                                        deliveryData.labelEs,
                                        style: AppTypography.of(context).bodySmall.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: deliveryColor,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      'Fecha: $sentAtLabel',
                                      style: AppTypography.of(context).bodySmall.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      'Canal: $channelLabel',
                                      style: AppTypography.of(context).bodySmall.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                    if ((invoice.sentBy ?? '').trim().isNotEmpty)
                                      Text(
                                        'Por: ${invoice.sentBy!.trim()}',
                                        style: AppTypography.of(context).bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                                if (deliveryStatus == 'failed' &&
                                    (invoice.deliveryError ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error: ${invoice.deliveryError!.trim()}',
                                    style: AppTypography.of(context).bodySmall.copyWith(
                                          color: cs.error,
                                        ),
                                  ),
                                ],
                                if (canChangeDelivery) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      PopupMenuButton<String>(
                                        tooltip: 'Marcar como enviada',
                                        enabled: !_updatingDelivery,
                                        onSelected: (value) => _markInvoiceSent(channel: value),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'manual',
                                            child: Text('Manual'),
                                          ),
                                          PopupMenuItem(
                                            value: 'email',
                                            child: Text('Email'),
                                          ),
                                          PopupMenuItem(
                                            value: 'whatsapp',
                                            child: Text('WhatsApp'),
                                          ),
                                        ],
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: cs.outlineVariant.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_updatingDelivery)
                                                const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              else
                                                const Icon(Icons.mark_email_read_outlined, size: 18),
                                              const SizedBox(width: 6),
                                              const Text('Marcar como enviada'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: _updatingDelivery ? null : _markInvoiceUnsent,
                                        icon: const Icon(Icons.mark_email_unread_outlined),
                                        label: const Text('Marcar como no enviada'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          InvoiceDetailHistoryCard(
                            title: l.invoiceChangeHistoryTitle,
                            history: history,
                            formatWhen: (h) {
                              return h.changedAt == null
                                  ? '-'
                                  : DateFormat.yMMMd(l.localeName)
                                      .add_Hm()
                                      .format(h.changedAt!.toLocal());
                            },
                          ),
                          const SizedBox(height: 8),
                          InvoiceDetailLines(
                            loading: _loading,
                            error: _error,
                            lines: _lines,
                            onRefresh: _fetchLines,
                            totalLabel:
                                '${l.invoiceTotalLabel}: ${NumberFormat.simpleCurrency(name: '').format(_total)}',
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      border: Border(
                        top: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasRecurrence) ...[
                          Tooltip(
                            message: occurrenceLabel == null
                                ? recurrenceLabel
                                : '$recurrenceLabel · $occurrenceLabel',
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(44, 40),
                              ),
                              child: SizedBox(
                                width: 44,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    Icons.repeat_rounded,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Tooltip(
                          message: statusInfoLabel,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(44, 40),
                            ),
                            child: SizedBox(
                              width: 44,
                              height: 40,
                              child: Center(
                                child: Icon(
                                  statusInfoIcon,
                                  color: statusInfoColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: isLinked
                              ? '${l.statementsInvoiceAlreadyLinkedBadge} ($linkedEntriesCount)'
                              : l.statementsUnlinked,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(44, 40),
                            ),
                            child: SizedBox(
                              width: 44,
                              height: 40,
                              child: Center(
                                child: Icon(
                                  isLinked
                                      ? Icons.link_rounded
                                      : Icons.link_off_rounded,
                                  color: isLinked
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InvoiceDetailFooterActions(
                          downloadTooltip: '${l.download} PDF',
                          previewTooltip: l.invoicePreviewCta,
                          primaryTooltip: '',
                          downloadIcon: _downloadingPdf
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                          previewIcon:
                              const Icon(Icons.picture_as_pdf_outlined),
                          primaryIcon: const SizedBox.shrink(),
                          onDownload: _downloadingPdf ? null : _downloadPdf,
                          onPreview: _previewing ? null : _previewPdf,
                          onPrimary: null,
                          primaryFilled: true,
                          showPrimary: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
