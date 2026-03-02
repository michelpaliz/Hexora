import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../statements_formatters.dart';
import 'invoice_link_dialog_state.dart';

/// Confirmation panel for step 3 of the invoice/expense link wizard
class InvoiceLinkConfirmation {
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

    final panelBorder = Border.all(color: cs.outlineVariant.withValues(alpha: 0.5));

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
    final totalValue = expenseOnly ? expenseTotalRaw : selectedInvoice?.total;
    final totalLabel = totalValue == null
        ? '-'
        : StatementsFormatters.formatCurrency(context, totalValue.toString());

    final statusRaw = expenseOnly
        ? (selectedExpense?['status'] ?? 'uploaded').toString()
        : (selectedInvoice?.status ?? 'draft');
    final statusColor = statusRaw == 'issued'
        ? const Color(0xFF2E7D32)
        : statusRaw == 'draft'
            ? const Color(0xFF795548)
            : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: panelBorder,
            color: cs.surfaceContainerLowest,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    expenseOnly ? 'Gasto a vincular' : 'Facturas a vincular',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      statusRaw,
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
                expenseOnly ? 'Total gasto' : 'Total factura',
                totalLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Confirmation checkbox
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: state.confirmLink
                  ? cs.primary.withValues(alpha: 0.5)
                  : panelBorder.top.color,
            ),
            color: state.confirmLink
                ? cs.primaryContainer.withValues(alpha: 0.15)
                : null,
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
}
