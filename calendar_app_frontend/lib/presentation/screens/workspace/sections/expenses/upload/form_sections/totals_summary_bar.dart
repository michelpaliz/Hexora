import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_compact_financial_summary.dart';

class ExpenseTotalsSummaryBar extends StatelessWidget {
  final String subtotal;
  final String? discount;
  final String? discountedBase;
  final String tax;
  final String total;

  const ExpenseTotalsSummaryBar({
    super.key,
    required this.subtotal,
    this.discount,
    this.discountedBase,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final items = <HexoraFinancialMetric>[
      HexoraFinancialMetric(
        label: (discount ?? '').trim().isEmpty
            ? l.expenseUploadLinesSubtotalLabel
            : 'Subtotal antes de descuento',
        value: subtotal,
      ),
      if ((discount ?? '').trim().isNotEmpty)
        HexoraFinancialMetric(
          label: 'Descuento',
          value: discount!,
          valueColor: cs.error,
        ),
      if ((discountedBase ?? '').trim().isNotEmpty)
        HexoraFinancialMetric(
          label: 'Base tras descuento',
          value: discountedBase!,
        ),
      HexoraFinancialMetric(
        label: l.expenseUploadLinesTaxLabel,
        value: tax,
      ),
      HexoraFinancialMetric(
        label: l.expenseUploadLinesTotalLabel,
        value: total,
        emphasized: true,
      ),
    ];

    return HexoraCompactFinancialSummary(metrics: items);
  }
}
