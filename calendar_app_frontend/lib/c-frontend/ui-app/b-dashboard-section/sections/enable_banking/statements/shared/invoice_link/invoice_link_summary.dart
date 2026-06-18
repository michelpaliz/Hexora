import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    final t = AppTypography.of(context);
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.38)),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Movimiento seleccionado',
                  style: t.bodyMedium.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryItem(
            t,
            cs,
            icon: Icons.tag_outlined,
            label: 'Lote',
            value: batchId,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            t,
            cs,
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: date,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            t,
            cs,
            icon: Icons.description_outlined,
            label: l.statementsHeaderDescription,
            value: description,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            t,
            cs,
            icon: Icons.person_outline,
            label: expenseOnly ? 'Proveedor' : l.statementsHeaderClient,
            value: counterparty,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            t,
            cs,
            icon: Icons.payments_outlined,
            label: l.statementsHeaderAmount,
            value: amount,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            t,
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
    AppTypography t,
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
                style: t.caption.copyWith(
                  fontSize: 11.5,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
