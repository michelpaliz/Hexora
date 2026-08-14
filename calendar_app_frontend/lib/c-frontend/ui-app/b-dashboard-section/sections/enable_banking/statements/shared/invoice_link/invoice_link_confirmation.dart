import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../statements_formatters.dart';
import 'invoice_link_dialog_state.dart';

/// Confirmation panel for step 3 of the invoice/expense link wizard
class InvoiceLinkConfirmation {
  static final InvoicesApi _invoicesApi = InvoicesApi();

  static Widget build(
    BuildContext context,
    InvoiceLinkDialogState state,
    bool expenseOnly,
    AppLocalizations l,
    ColorScheme cs,
    VoidCallback onStateChanged,
  ) {
    final selectedInvoice = state.getSelectedInvoice();
    final selectedInvoices = state.getSelectedInvoices();
    final selectedExpense = state.getSelectedExpense();

    final panelBorder =
        Border.all(color: cs.outlineVariant.withValues(alpha: 0.38));

    if ((expenseOnly && selectedExpense == null) ||
        (!expenseOnly && selectedInvoices.isEmpty)) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: panelBorder,
        ),
        child: Text(
          'Paso 3: selecciona una factura para revisar el detalle y confirmar.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    // Get issue date
    final expenseIssueRaw = selectedExpense?['issueDate']?.toString();
    final issueDate = expenseOnly
        ? DateTime.tryParse(expenseIssueRaw ?? '')
        : selectedInvoice?.issueDate;
    final issueLabel = issueDate == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).format(issueDate);

    // Get total
    final expenseTotalRaw = selectedExpense?['total'];
    final invoiceTotal = selectedInvoices.fold<num>(
      0,
      (sum, invoice) => sum + (invoice.total ?? 0),
    );
    final totalValue = expenseOnly ? expenseTotalRaw : invoiceTotal;
    final totalLabel = totalValue == null
        ? '-'
        : StatementsFormatters.formatCurrency(context, totalValue.toString());

    final statusRaw = expenseOnly
        ? (selectedExpense?['status'] ?? 'uploaded').toString()
        : (selectedInvoice?.status ?? 'draft');
    final statusLabel = _statusLabel(statusRaw);
    final statusColor = statusRaw == 'issued'
        ? const Color(0xFF2E7D32)
        : statusRaw == 'draft'
            ? const Color(0xFF795548)
            : cs.onSurfaceVariant;
    final clientName = !expenseOnly
        ? _firstNonEmpty([
            selectedInvoice?.clientSnapshot?.legalName,
            selectedInvoice?.billingName,
            selectedInvoice?.clientName,
          ])
        : null;
    final clientTaxId = !expenseOnly
        ? _firstNonEmpty([
            selectedInvoice?.clientSnapshot?.taxId,
          ])
        : null;
    final clientContact = !expenseOnly
        ? _joinNonEmpty([
            selectedInvoice?.clientSnapshot?.email,
            selectedInvoice?.clientSnapshot?.phone,
          ], separator: ' · ')
        : '';
    final clientAddress = !expenseOnly
        ? _joinNonEmpty([
            selectedInvoice?.clientSnapshot?.addressStreet ??
                selectedInvoice?.addressStreet,
            selectedInvoice?.clientSnapshot?.addressPostalCode ??
                selectedInvoice?.addressPostalCode,
            selectedInvoice?.clientSnapshot?.addressCity ??
                selectedInvoice?.addressCity,
            selectedInvoice?.clientSnapshot?.addressProvince ??
                selectedInvoice?.addressProvince,
          ], separator: ', ')
        : '';
    final invoiceRows = !expenseOnly
        ? selectedInvoices.map((inv) {
            final number =
                inv.invoiceNumber.trim().isEmpty ? inv.id : inv.invoiceNumber;
            final total = inv.total == null
                ? '-'
                : StatementsFormatters.formatCurrency(
                    context,
                    inv.total.toString(),
                  );
            return '$number · $total';
          }).toList(growable: false)
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: panelBorder,
            color: cs.surface.withValues(alpha: 0.34),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expenseOnly
                              ? 'Gasto a vincular'
                              : 'Facturas a vincular',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          expenseOnly
                              ? 'Revisa el documento seleccionado'
                              : '${selectedInvoices.length} factura${selectedInvoices.length == 1 ? '' : 's'} seleccionada${selectedInvoices.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (expenseOnly)
                _infoRow(
                  cs,
                  'Documento',
                  (selectedExpense?['invoiceNumber']
                              ?.toString()
                              .trim()
                              .isNotEmpty ??
                          false)
                      ? selectedExpense!['invoiceNumber'].toString()
                      : (selectedExpense?['id'] ??
                              selectedExpense?['_id'] ??
                              selectedExpense?['expenseId'] ??
                              '-')
                          .toString(),
                )
              else
                _infoRow(
                  cs,
                  selectedInvoices.length == 1 ? 'Factura' : 'Facturas',
                  selectedInvoices
                      .map((inv) => inv.invoiceNumber.trim().isEmpty
                          ? inv.id
                          : inv.invoiceNumber)
                      .join(', '),
                ),
              const SizedBox(height: 6),
              _infoRow(cs, 'Emisión', issueLabel),
              const SizedBox(height: 6),
              _infoRow(
                cs,
                expenseOnly
                    ? 'Total gasto'
                    : selectedInvoices.length == 1
                        ? 'Total factura'
                        : 'Total facturas',
                totalLabel,
              ),
              if (!expenseOnly) ...[
                const SizedBox(height: 14),
                _sectionDivider(cs, 'Cliente'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _detailPill(
                      cs,
                      icon: Icons.business_outlined,
                      label: 'Nombre',
                      value: clientName ?? '-',
                    ),
                    _detailPill(
                      cs,
                      icon: Icons.badge_outlined,
                      label: 'CIF/NIF',
                      value: clientTaxId ?? '-',
                    ),
                    if (clientAddress.isNotEmpty)
                      _detailPill(
                        cs,
                        icon: Icons.location_on_outlined,
                        label: 'Direccion',
                        value: clientAddress,
                        wide: true,
                      ),
                    if (clientContact.isNotEmpty)
                      _detailPill(
                        cs,
                        icon: Icons.alternate_email_rounded,
                        label: 'Contacto',
                        value: clientContact,
                        wide: true,
                      ),
                  ],
                ),
                if (invoiceRows.length > 1) ...[
                  const SizedBox(height: 14),
                  _sectionDivider(cs, 'Detalle de facturas'),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int index = 0;
                          index < selectedInvoices.length;
                          index++) ...[
                        if (index > 0) const SizedBox(height: 8),
                        _invoicePreviewRow(
                          context,
                          cs,
                          l,
                          selectedInvoices[index],
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Confirmation checkbox
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.confirmLink
                  ? cs.primary.withValues(alpha: 0.5)
                  : panelBorder.top.color,
            ),
            color: state.confirmLink
                ? cs.primary.withValues(alpha: 0.12)
                : cs.surface.withValues(alpha: 0.22),
          ),
          child: CheckboxListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            value: state.confirmLink,
            onChanged: (v) {
              state.confirmLink = v == true;
              onStateChanged();
            },
            title: Text(
              expenseOnly
                  ? 'Confirmo vincular este movimiento con este gasto'
                  : 'Confirmo vincular este movimiento con '
                      '${selectedInvoices.length} '
                      'factura${selectedInvoices.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }

  static Widget _infoRow(ColorScheme cs, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _sectionDivider(ColorScheme cs, String label) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
      ],
    );
  }

  static Widget _detailPill(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
    bool wide = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: wide ? 260 : 190,
        maxWidth: wide ? 420 : 260,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 15, color: cs.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '-' : value,
                    maxLines: wide ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _invoicePreviewRow(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l,
    Invoice invoice,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final number = invoice.invoiceNumber.trim().isEmpty
        ? invoice.id
        : invoice.invoiceNumber;
    final issueDate = invoice.issueDate == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).format(invoice.issueDate!);
    final total = invoice.total == null
        ? '-'
        : StatementsFormatters.formatCurrency(
            context,
            invoice.total.toString(),
          );
    final normalizedStatus = invoice.status?.trim() ?? '';
    final statusRaw = normalizedStatus.isEmpty ? 'draft' : normalizedStatus;
    final statusLabel = _statusLabel(statusRaw);
    final statusColor = statusRaw == 'issued'
        ? const Color(0xFF2E7D32)
        : statusRaw == 'draft'
            ? const Color(0xFF795548)
            : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.16)
            : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withValues(alpha: 0.28)
              : const Color(0xFFD9E6F7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.receipt_long_outlined,
              size: 16,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _miniMetaChip(
                      cs,
                      icon: Icons.event_outlined,
                      label: issueDate,
                      isDark: isDark,
                    ),
                    _miniMetaChip(
                      cs,
                      icon: Icons.verified_outlined,
                      label: statusLabel,
                      color: statusColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            total,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          _previewInvoiceButton(context, cs, invoice),
        ],
      ),
    );
  }

  static Widget _miniMetaChip(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final foreground = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? cs.onSurfaceVariant).withValues(
          alpha: isDark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (color ?? cs.outline).withValues(alpha: isDark ? 0.24 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _previewInvoiceButton(
    BuildContext context,
    ColorScheme cs,
    Invoice invoice,
  ) {
    return Tooltip(
      message: 'Vista previa PDF',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          try {
            final response = await _invoicesApi.previewPdf(invoice.id);
            final bytes = InvoiceEditorPdf.validatePdf(response);
            final label = invoice.invoiceNumber.trim().isEmpty
                ? invoice.id
                : invoice.invoiceNumber.trim();
            await pdf_launcher.launchPdfPreview(
              bytes,
              fileName: 'invoice-preview-$label.pdf',
            );
          } catch (e) {
            if (!context.mounted) return;
            final msg = e.toString().replaceFirst('Exception: ', '').trim();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  msg.isEmpty ? 'No se pudo previsualizar el PDF' : msg,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            Icons.picture_as_pdf_outlined,
            size: 15,
            color: cs.primary,
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'issued':
        return 'Emitida';
      case 'draft':
        return 'Borrador';
      case 'uploaded':
        return 'Subida';
      case 'paid':
        return 'Pagada';
      case 'cancelled':
      case 'canceled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static String _joinNonEmpty(
    List<String?> values, {
    required String separator,
  }) {
    return values
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(separator);
  }
}
