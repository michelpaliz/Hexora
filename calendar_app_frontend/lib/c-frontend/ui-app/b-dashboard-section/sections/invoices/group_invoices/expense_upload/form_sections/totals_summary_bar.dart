import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    final items = <Widget>[
      _SummaryItem(
        label: (discount ?? '').trim().isEmpty
            ? l.expenseUploadLinesSubtotalLabel
            : 'Subtotal antes de descuento',
        value: subtotal,
      ),
      if ((discount ?? '').trim().isNotEmpty)
        _SummaryItem(
          label: 'Descuento',
          value: discount!,
          errorHighlight: true,
        ),
      if ((discountedBase ?? '').trim().isNotEmpty)
        _SummaryItem(
          label: 'Base tras descuento',
          value: discountedBase!,
        ),
      _SummaryItem(
        label: l.expenseUploadLinesTaxLabel,
        value: tax,
      ),
      _SummaryItem(
        label: l.expenseUploadLinesTotalLabel,
        value: total,
        highlight: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: items,
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool errorHighlight;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.highlight = false,
    this.errorHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = errorHighlight
        ? cs.error
        : highlight
            ? cs.primary
            : cs.onSurface;
    final style = (highlight || errorHighlight)
        ? t.bodySmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: color,
          )
        : t.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}
