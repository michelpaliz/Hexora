import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

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
    final rows = <({String label, String value, Color? color})>[
      (
        label: (discount ?? '').trim().isEmpty
            ? l.expenseUploadLinesSubtotalLabel
            : 'Subtotal antes de descuento',
        value: subtotal,
        color: null,
      ),
      if ((discount ?? '').trim().isNotEmpty)
        (
          label: 'Descuento',
          value: discount!,
          color: cs.error,
        ),
      if ((discountedBase ?? '').trim().isNotEmpty)
        (
          label: 'Base tras descuento',
          value: discountedBase!,
          color: null,
        ),
      (
        label: l.expenseUploadLinesTaxLabel,
        value: tax,
        color: null,
      ),
    ];

    TextStyle? rowStyle(Color? color) =>
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color ?? cs.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .34)),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(row.value,
                      textAlign: TextAlign.right, style: rowStyle(row.color)),
                ],
              ),
            ),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: .38),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .07),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.expenseUploadLinesTotalLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  total,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
