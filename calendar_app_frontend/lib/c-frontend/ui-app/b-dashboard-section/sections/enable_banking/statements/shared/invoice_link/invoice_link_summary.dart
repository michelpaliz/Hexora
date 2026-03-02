import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../statements_shared_utils.dart';
import 'invoice_link_dialog_state.dart';

/// Summary panel showing the selected statement entry details
class InvoiceLinkSummary {
  static Widget build(
    BuildContext context,
    Map<String, dynamic> entry,
    InvoiceLinkDialogState state,
    bool expenseOnly,
    StatementsController s,
    AppLocalizations l,
    ColorScheme cs,
  ) {
    final batchId = StatementsSharedUtils.entryText(entry, ['_batchId', 'batchId', '_id', 'id']);
    final date = StatementsSharedUtils.entryText(entry, ['valueDate', 'date']);
    final description = StatementsSharedUtils.entryText(entry, ['description']);
    final amountRaw = StatementsSharedUtils.entryText(entry, ['amount']);
    final balanceRaw = StatementsSharedUtils.entryText(entry, ['balance']);

    final amount = amountRaw.isEmpty
        ? '-'
        : StatementsFormatters.formatCurrency(context, amountRaw);
    final balance = balanceRaw.isEmpty
        ? '-'
        : StatementsFormatters.formatCurrency(context, balanceRaw);
    final client = StatementsSharedUtils.clientLabel(l, s, entry);
    final providerName = StatementsSharedUtils.entryText(entry, ['providerName', 'vendorName', 'vendor']);

    final counterparty = expenseOnly
        ? (providerName.isEmpty
            ? (state.selectedProviderId ?? l.statementsUnlinked)
            : providerName)
        : client;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Movimiento seleccionado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _summaryItem(
            cs,
            icon: Icons.tag_outlined,
            label: 'Lote',
            value: batchId,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            cs,
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: date,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            cs,
            icon: Icons.description_outlined,
            label: l.statementsHeaderDescription,
            value: description,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            cs,
            icon: Icons.person_outline,
            label: expenseOnly ? 'Proveedor' : l.statementsHeaderClient,
            value: counterparty,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            cs,
            icon: Icons.payments_outlined,
            label: l.statementsHeaderAmount,
            value: amount,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            cs,
            icon: Icons.account_balance_wallet_outlined,
            label: l.statementsHeaderBalance,
            value: balance,
          ),
        ],
      ),
    );
  }

  static Widget _summaryItem(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
