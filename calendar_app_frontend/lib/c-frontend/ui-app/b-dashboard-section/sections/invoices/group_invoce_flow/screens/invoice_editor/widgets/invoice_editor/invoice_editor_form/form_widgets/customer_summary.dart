import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'currency_pill.dart';

class CustomerCollapsedSummary extends StatelessWidget {
  final String clientName;
  final String currency;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final int issuedCount;
  final int pendingDrafts;
  final bool loading;
  final VoidCallback onExpand;

  const CustomerCollapsedSummary({
    super.key,
    required this.clientName,
    required this.currency,
    required this.invoiceDate,
    required this.dueDate,
    required this.issuedCount,
    required this.pendingDrafts,
    required this.loading,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd();
    final inv = invoiceDate == null ? '-' : dateFmt.format(invoiceDate!);
    final due = dueDate == null ? '-' : dateFmt.format(dueDate!);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onExpand,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clientName,
                          style: t.bodyMedium
                              .copyWith(fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CurrencyPill(currency: currency),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l.invoiceDateLabel}: $inv • ${l.invoiceDueDateLabel}: $due',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (loading)
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MiniPill(
                          label: l.invoiceClientInvoicesThisMonthLabel,
                          value: '$issuedCount',
                        ),
                        MiniPill(
                          label: l.invoicePendingDraftsLabel,
                          value: '$pendingDrafts',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.unfold_more, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class MiniPill extends StatelessWidget {
  final String label;
  final String value;
  const MiniPill({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
