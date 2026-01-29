import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'summary_layout.dart';

class InvoiceSummaryLinesAndTotals extends StatefulWidget {
  final List<LineDraft> lines;
  final num subtotal;
  final num tax;
  final num total;

  const InvoiceSummaryLinesAndTotals({
    super.key,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  State<InvoiceSummaryLinesAndTotals> createState() =>
      _InvoiceSummaryLinesAndTotalsState();
}

class _InvoiceSummaryLinesAndTotalsState
    extends State<InvoiceSummaryLinesAndTotals> {
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final currencyFormatter = NumberFormat.simpleCurrency(name: '');
    final linesHeaderStyle = t.bodyMedium.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final priceAccent = cs.primary;
    final priceMuted = cs.primary.withValues(alpha: 0.75);
    final totalChipBg = cs.primaryContainer.withValues(alpha: 0.75);

    final linesTable = Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: InvoiceSummaryLayout.minDescWidth,
              child: Text(
                l.lineDescription,
                style: linesHeaderStyle,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: InvoiceSummaryLayout.gap),
            SizedBox(
              width: InvoiceSummaryLayout.qtyWidth,
              child: Text(
                l.lineQuantity,
                style: linesHeaderStyle,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: InvoiceSummaryLayout.gap),
            SizedBox(
              width: InvoiceSummaryLayout.unitWidth,
              child: Text(
                l.lineUnitPrice,
                style: linesHeaderStyle,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: InvoiceSummaryLayout.gap),
            SizedBox(
              width: InvoiceSummaryLayout.vatWidth,
              child: Text(
                '${l.taxRateShort}%',
                style: linesHeaderStyle,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: InvoiceSummaryLayout.gap),
            SizedBox(
              width: InvoiceSummaryLayout.totalWidth,
              child: Text(
                l.invoiceTotalLabel,
                style: linesHeaderStyle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.lines.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.invoiceNoLinesYet,
              style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          ...widget.lines.map((line) {
            final qty = line.quantity ?? 1;
            final unit = line.unitPrice ?? 0;
            final vat = line.taxRate ?? 21;
            final subtotal = qty * unit;
            final tax = subtotal * (vat / 100);
            final total = subtotal + tax;
            final desc = line.description.text.trim().isEmpty
                ? '—'
                : line.description.text.trim();

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: InvoiceSummaryLayout.minDescWidth,
                    child: Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: InvoiceSummaryLayout.gap),
                  SizedBox(
                    width: InvoiceSummaryLayout.qtyWidth,
                    child: Text(
                      NumberFormat.compact().format(qty),
                      style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: InvoiceSummaryLayout.gap),
                  SizedBox(
                    width: InvoiceSummaryLayout.unitWidth,
                    child: Text(
                      currencyFormatter.format(unit),
                      style: t.bodyMedium.copyWith(
                        color: priceMuted,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: InvoiceSummaryLayout.gap),
                  SizedBox(
                    width: InvoiceSummaryLayout.vatWidth,
                    child: Text(
                      '${vat.toString()}%',
                      style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: InvoiceSummaryLayout.gap),
                  SizedBox(
                    width: InvoiceSummaryLayout.totalWidth,
                    child: Text(
                      currencyFormatter.format(total),
                      style: t.bodyMedium.copyWith(
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

    Widget totalsRow({
      required String label,
      required String value,
      bool strong = false,
    }) {
      final row = Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (strong ? t.bodyLarge : t.bodyMedium).copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: InvoiceSummaryLayout.totalWidth,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (strong ? t.bodyLarge : t.bodyMedium).copyWith(
                color: strong ? priceAccent : cs.onSurface,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      );
      if (!strong) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: row,
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: totalChipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: priceAccent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: row,
        ),
      );
    }

    final totals = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          totalsRow(
            label: l.invoiceSubtotalLabel,
            value: currencyFormatter.format(widget.subtotal),
          ),
          totalsRow(
            label: l.invoiceTaxLabel,
            value: currencyFormatter.format(widget.tax),
          ),
          const SizedBox(height: 6),
          totalsRow(
            label: l.invoiceTotalLabel,
            value: currencyFormatter.format(widget.total),
            strong: true,
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollable =
            constraints.maxWidth < InvoiceSummaryLayout.minLinesTableWidth;

        final content = SizedBox(
          width: InvoiceSummaryLayout.minLinesTableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              linesTable,
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              totals,
            ],
          ),
        );

        if (!scrollable) {
          return Align(alignment: Alignment.centerLeft, child: content);
        }

        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (n) => n.depth == 0,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: content,
          ),
        );
      },
    );
  }
}
