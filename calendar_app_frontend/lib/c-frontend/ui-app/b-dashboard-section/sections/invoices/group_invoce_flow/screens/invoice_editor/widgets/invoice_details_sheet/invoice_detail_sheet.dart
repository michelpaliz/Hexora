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
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_dates.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_history_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_lines.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_party.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_email_widgets.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_payment_editor.dart';
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

String _truncateId(String id) =>
    id.length <= 12 ? id : '${id.substring(0, 8)}…';

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
    final deliveryData = invoiceDeliveryViewData(invoice.deliveryStatus);
    final deliveryColor = invoiceDeliveryColor(cs, deliveryData.visual);
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.4,
        maxChildSize: 0.96,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
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
                              style:
                                  AppTypography.of(context).bodyLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface,
                                      ),
                            ),
                            Text(
                              invoice.invoiceNumber,
                              style:
                                  AppTypography.of(context).bodySmall.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                              style: AppTypography.of(context)
                                  .bodySmall
                                  .copyWith(
                                    color:
                                        _statusColor(cs, invoice.status ?? ''),
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
                    if ((settlement.advanceInvoiceNumber ?? '')
                        .trim()
                        .isNotEmpty)
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
                canEdit:
                    !(invoice.status ?? '').toLowerCase().contains('draft'),
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
              deliveryData: deliveryData,
              deliveryColor: deliveryColor,
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
          ],
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
    final issuedByName = invoice.issuedByDisplayName;
    final issuedByLabel = issuedByName == null
        ? (isEs ? 'Emisor no registrado' : 'Issuer not recorded')
        : (isEs ? 'Emitida por $issuedByName' : 'Issued by $issuedByName');
    final issuedAtLabel = invoice.issuedAtResolved == null
        ? null
        : DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(invoice.issuedAtResolved!.toLocal());

    return ColoredBox(
      color: Theme.of(context).canvasColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.85;

          // Reserve: top padding(6) + header(~72) + gap(8) + footer(56) + bottom(8) = ~150
          final pdfHeight = (availableH - 150).clamp(240.0, double.infinity);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: InvoiceDetailHeader(
                  clientName: widget.client.name,
                  invoiceNumber: invoice.invoiceNumber,
                  hasRecurrence: hasRecurrence,
                  recurrenceLabel: recurrenceLabel,
                  occurrenceLabel: occurrenceLabel,
                  recurrenceButtonLabel: l.invoiceRecurringLabel,
                  onOpenRecurringSeries: widget.onOpenRecurringSeries,
                  recurringSeriesId: invoice.recurringSeriesId,
                  statusLabel: _resolveStatus(status),
                  statusColor: _statusColor(cs, status),
                  statusIcon: _statusIcon(status),
                  total: _total.toDouble(),
                  invoiceType: invoice.invoiceType,
                  issuedByLabel:
                      status.contains('issue') ? issuedByLabel : null,
                  issuedAtLabel:
                      status.contains('issue') ? issuedAtLabel : null,
                ),
              ),

              // ── PDF Preview ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: pdfHeight,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: _buildPdfArea(cs, l),
                  ),
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
          );
        },
      ),
    );
  }

  // ── PDF area widget ─────────────────────────────────────────────────────────

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
          return PdfInlinePreview(bytes: _inlinePdfBytes!, height: h);
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
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Details – primary CTA (expands)
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _openDetailsDialog(context),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: Text(isEs ? 'Ver detalles' : 'Details'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Recurrence badge
          if (hasRecurrence) ...[
            _FooterIconBtn(
              icon: Icons.repeat_rounded,
              color: cs.primary,
              tooltip: occurrenceLabel == null
                  ? recurrenceLabel
                  : '$recurrenceLabel · $occurrenceLabel',
              onTap: () {},
            ),
          ],

          // Link status
          _FooterIconBtn(
            icon: isLinked ? Icons.link_rounded : Icons.link_off_rounded,
            color: isLinked ? cs.primary : cs.onSurfaceVariant,
            tooltip: isLinked
                ? '${l.statementsInvoiceAlreadyLinkedBadge} ($linkedEntriesCount)'
                : l.statementsUnlinked,
            onTap: () {},
          ),

          // Download
          _FooterIconBtn(
            icon: _downloadingPdf
                ? Icons.hourglass_empty_rounded
                : Icons.download_outlined,
            color: cs.onSurfaceVariant,
            tooltip: '${l.download} PDF',
            onTap: _downloadingPdf ? null : _downloadPdf,
          ),

          // Preview PDF
          _FooterIconBtn(
            icon: Icons.open_in_full_rounded,
            color: cs.onSurfaceVariant,
            tooltip: l.invoicePreviewCta,
            onTap: _previewing ? null : _previewPdf,
          ),
        ],
      ),
    );
  }
}

// ── Footer icon button ─────────────────────────────────────────────────────────

class _FooterIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _FooterIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: onTap == null ? color.withValues(alpha: 0.4) : color,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      ),
    );
  }
}

// ── Detail section wrapper ─────────────────────────────────────────────────────

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
  final InvoiceDeliveryViewData deliveryData;
  final Color deliveryColor;
  final String deliveryStatus;
  final String sentAtLabel;
  final String channelLabel;
  final bool canChangeDelivery;
  final bool updatingDelivery;
  final Future<void> Function({required String channel}) onMarkSent;
  final VoidCallback onMarkUnsent;

  const _DeliverySection({
    required this.invoice,
    required this.deliveryData,
    required this.deliveryColor,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: deliveryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: deliveryColor.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    deliveryData.labelEs,
                    style: AppTypography.of(context).bodySmall.copyWith(
                          color: deliveryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                  ),
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
                        PopupMenuItem(value: 'manual', child: Text('Manual')),
                        PopupMenuItem(value: 'email', child: Text('Email')),
                        PopupMenuItem(
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
