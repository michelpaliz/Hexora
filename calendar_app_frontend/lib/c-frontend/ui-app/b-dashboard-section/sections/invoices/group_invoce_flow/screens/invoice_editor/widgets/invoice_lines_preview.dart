import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceLinesPreview extends StatelessWidget {
  final List<InvoiceLine> lines;
  const InvoiceLinesPreview({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat.simpleCurrency(name: '', locale: l.localeName);
    final intFormat = NumberFormat.decimalPattern(l.localeName);

    if (lines.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.invoiceLinesPlaceholderTitle,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              l.invoiceLinesPlaceholderSubtitle,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          _LineRow(
            line: lines[i],
            money: money,
            intFormat: intFormat,
          ),
          if (i < lines.length - 1)
            Divider(
              height: 20,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
        ],
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final InvoiceLine line;
  final NumberFormat money;
  final NumberFormat intFormat;

  const _LineRow({
    required this.line,
    required this.money,
    required this.intFormat,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final qty = line.quantity;
    final unit = line.unitPrice;
    final tax = line.taxRate;
    final subtotal = line.lineSubtotal ?? (qty * unit);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.description,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.lineQuantity}: ${intFormat.format(qty)} × ${money.format(unit)}',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${l.invoiceTaxLabel}: ${intFormat.format(tax)}%',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          money.format(subtotal),
          style: t.bodyMedium.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
