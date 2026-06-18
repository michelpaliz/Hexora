import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_lines_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceDetailLines extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<InvoiceLine> lines;
  final Future<void> Function() onRefresh;
  final num? subtotal;
  final num? taxTotal;
  final num? total;
  final num? discountAmount;
  final num? discountPercent;

  const InvoiceDetailLines({
    super.key,
    required this.loading,
    required this.error,
    required this.lines,
    required this.onRefresh,
    this.subtotal,
    this.taxTotal,
    this.total,
    this.discountAmount,
    this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat.simpleCurrency(name: '', locale: l.localeName);

    num lineSubtotal(InvoiceLine line) =>
        line.lineSubtotal ?? (line.quantity * line.unitPrice);
    num lineTax(InvoiceLine line) =>
        line.lineTax ?? (lineSubtotal(line) * (line.taxRate / 100));
    num lineTotal(InvoiceLine line) =>
        line.lineTotal ?? (lineSubtotal(line) + lineTax(line));

    final linesSubtotal =
        lines.fold<num>(0, (sum, line) => sum + lineSubtotal(line));
    final linesTaxTotal = lines.fold<num>(0, (sum, line) => sum + lineTax(line));
    final linesTotal = lines.fold<num>(0, (sum, line) => sum + lineTotal(line));

    final discountByAmount = (discountAmount ?? 0).toDouble();
    final discountByPercent =
        discountByAmount <= 0 && (discountPercent ?? 0) > 0
            ? (linesSubtotal.toDouble() * (discountPercent!.toDouble() / 100))
            : 0.0;
    final effectiveDiscount = (discountByAmount > 0 ? discountByAmount : discountByPercent)
        .clamp(0, linesSubtotal.toDouble());

    final effectiveSubtotal = subtotal ?? (linesSubtotal - effectiveDiscount);
    final effectiveTaxTotal = taxTotal ?? linesTaxTotal;
    final effectiveTotal = total ?? linesTotal;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final partialSubtotalLabel = isEs ? 'Total parcial' : 'Partial subtotal';
    final discountLabel = isEs ? 'Descuento' : 'Discount';

    TextStyle amountStyle({bool strong = false}) {
      return t.bodySmall.copyWith(
        fontFamily: 'monospace',
        fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
        color: cs.onSurface,
      );
    }

    Widget totalsRow({
      required String label,
      required String value,
      bool strong = false,
    }) {
      return Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: amountStyle(strong: strong),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.invoiceLinesTitle,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            IconButton(
              tooltip: l.refreshButton,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          ),
        if (!loading) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: InvoiceLinesPreview(lines: lines),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border(
                      top: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      totalsRow(
                        label: l.invoiceSubtotalLabel,
                        value: money.format(effectiveSubtotal),
                      ),
                      if (effectiveDiscount > 0) ...[
                        const SizedBox(height: 3),
                        totalsRow(
                          label: partialSubtotalLabel,
                          value: money.format(linesSubtotal),
                        ),
                        const SizedBox(height: 3),
                        totalsRow(
                          label: discountLabel,
                          value: '-${money.format(effectiveDiscount)}',
                        ),
                      ],
                      const SizedBox(height: 3),
                      totalsRow(
                        label: l.invoiceTaxLabel,
                        value: money.format(effectiveTaxTotal),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.invoiceTotalLabel,
                              style: t.bodyMedium.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            money.format(effectiveTotal),
                            style: amountStyle(strong: true).copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
