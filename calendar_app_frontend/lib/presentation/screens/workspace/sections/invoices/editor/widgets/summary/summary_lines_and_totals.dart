import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceSummaryLinesAndTotals extends StatelessWidget {
  final List<LineDraft> lines;
  final num? partialSubtotal;
  final num discountAmount;
  final num? taxableBase;
  final num subtotal;
  final num tax;
  final num total;
  final bool showTax;

  const InvoiceSummaryLinesAndTotals({
    super.key,
    required this.lines,
    this.partialSubtotal,
    this.discountAmount = 0,
    this.taxableBase,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.showTax = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final currencyFormatter = NumberFormat.simpleCurrency(name: '');
    const tabularFigures = [FontFeature.tabularFigures()];
    final priceAccent = cs.primary;

    final headerStyle = t.bodyMedium.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final numericStyle = t.bodyMedium.copyWith(
      fontFeatures: tabularFigures,
    );

    Widget totalsRow({
      required String label,
      required String value,
      bool strong = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: (strong ? t.bodyLarge : t.bodyMedium).copyWith(
                  color: strong ? cs.onSurface : cs.onSurfaceVariant,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              textAlign: TextAlign.right,
              style: (strong ? t.bodyLarge : t.bodyMedium).copyWith(
                color: strong ? priceAccent : cs.onSurface,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      );
    }

    final totals = Column(
      children: [
        totalsRow(
          label: (discountAmount > 0 && partialSubtotal != null)
              ? 'Total parcial'
              : l.invoiceSubtotalLabel,
          value: currencyFormatter.format(
            (discountAmount > 0 && partialSubtotal != null)
                ? partialSubtotal
                : subtotal,
          ),
        ),
        if (discountAmount > 0)
          totalsRow(
            label: 'Descuento',
            value: '-${currencyFormatter.format(discountAmount)}',
          ),
        if (discountAmount > 0)
          totalsRow(
            label: 'Base imponible',
            value: currencyFormatter.format(taxableBase ?? subtotal),
          ),
        if (showTax)
          totalsRow(
            label: l.invoiceTaxLabel,
            value: currencyFormatter.format(tax),
          ),
        const SizedBox(height: 4),
        totalsRow(
          label: l.invoiceTotalLabel,
          value: currencyFormatter.format(total),
          strong: true,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 480;

        Widget linesSection;

        if (lines.isEmpty) {
          linesSection = Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.invoiceNoLinesYet,
              style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        } else if (narrow) {
          linesSection = Column(
            children: lines.map((line) {
              final qty = line.quantity ?? 1;
              final unit = line.unitPrice ?? 0;
              final vat = line.taxRate ?? 21;
              final lineSubtotal = qty * unit;
              final lineTax = showTax ? lineSubtotal * (vat / 100) : 0;
              final lineTotal = lineSubtotal + lineTax;
              final rawDesc = line.description.text.trim();
              final desc = rawDesc.isEmpty ? '--' : rawDesc;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            desc,
                            style: t.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$qty × ${currencyFormatter.format(unit)}${showTax ? '  ·  $vat% IVA' : ''}',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormatter.format(lineTotal),
                      style: numericStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: priceAccent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        } else {
          linesSection = Column(
            children: [
              Row(
                children: [
                  Expanded(
                      flex: 5,
                      child: Text(l.lineDescription, style: headerStyle)),
                  Expanded(
                    flex: 2,
                    child: Text(l.lineQuantity,
                        textAlign: TextAlign.right, style: headerStyle),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l.lineUnitPrice,
                        textAlign: TextAlign.right, style: headerStyle),
                  ),
                  if (showTax)
                    Expanded(
                      flex: 2,
                      child: Text('${l.taxRateShort}%',
                          textAlign: TextAlign.right, style: headerStyle),
                    ),
                  Expanded(
                    flex: 2,
                    child: Text(l.invoiceTotalLabel,
                        textAlign: TextAlign.right, style: headerStyle),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 6),
              ...lines.map((line) {
                final qty = line.quantity ?? 1;
                final unit = line.unitPrice ?? 0;
                final vat = line.taxRate ?? 21;
                final lineSubtotal = qty * unit;
                final lineTax = showTax ? lineSubtotal * (vat / 100) : 0;
                final lineTotal = lineSubtotal + lineTax;
                final rawDesc = line.description.text.trim();
                final desc = rawDesc.isEmpty ? '--' : rawDesc;
                final descLines = desc.split('\n');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              descLines.first,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (descLines.length > 1)
                              for (final lineText in descLines.skip(1))
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    lineText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.compact().format(qty),
                          style: numericStyle.copyWith(
                              color: cs.onSurfaceVariant),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          currencyFormatter.format(unit),
                          style: numericStyle.copyWith(
                            color: priceAccent.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      if (showTax)
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$vat%',
                            style: numericStyle.copyWith(
                                color: cs.onSurfaceVariant),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          currencyFormatter.format(lineTotal),
                          style: numericStyle.copyWith(
                            color: priceAccent,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            linesSection,
            const SizedBox(height: 8),
            Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            totals,
          ],
        );
      },
    );
  }
}
