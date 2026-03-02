import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseVatBreakdownCard extends StatelessWidget {
  final List<Map<String, dynamic>>? breakdown;

  const ExpenseVatBreakdownCard({
    super.key,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    if (breakdown == null || breakdown!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.expenseUploadVatBreakdownTitle, style: t.bodyMedium),
            const SizedBox(height: 8),
            for (final row in breakdown!) ...[
              _VatRow(
                rate: (row['rate'] ?? '').toString(),
                base: (row['base'] ?? '').toString(),
                tax: (row['tax'] ?? '').toString(),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _VatRow extends StatelessWidget {
  final String rate;
  final String base;
  final String tax;

  const _VatRow({
    required this.rate,
    required this.base,
    required this.tax,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final formattedBase = formatMoneyEu(base, fallback: base);
    final formattedTax = formatMoneyEu(tax, fallback: tax);
    return Row(
      children: [
        Expanded(
          child: Text(
            '${l.expenseUploadVatRateLabel} $rate',
            style: t.bodySmall,
          ),
        ),
        Text(
          '${l.expenseUploadVatBaseLabel} $formattedBase',
          style: t.bodySmall,
        ),
        const SizedBox(width: 12),
        Text(
          '${l.expenseUploadVatTaxLabel} $formattedTax',
          style: t.bodySmall,
        ),
      ],
    );
  }
}
