import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'summary_chips.dart';
import 'summary_header.dart';
import 'summary_info_box.dart';
import 'summary_lines_and_totals.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final String invoiceNumber;
  final String issuerName;
  final GroupClient? client;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final String notes;
  final List<LineDraft> lines;
  final Invoice? savedInvoice;
  final bool fillHeight;

  const InvoiceSummaryCard({
    super.key,
    required this.invoiceNumber,
    required this.issuerName,
    required this.client,
    required this.invoiceDate,
    required this.dueDate,
    required this.notes,
    required this.lines,
    required this.savedInvoice,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    num subtotal = 0;
    num tax = 0;
    for (final line in lines) {
      final qty = line.quantity ?? 1;
      final price = line.unitPrice ?? 0;
      final taxRate = line.taxRate ?? 21;
      final s = qty * price;
      final v = s * (taxRate / 100);
      subtotal += s;
      tax += v;
    }
    final total = subtotal + tax;

    final status =
        (savedInvoice?.status?.isNotEmpty == true) ? savedInvoice!.status! : 'draft';

    final dateFmt = DateFormat.yMMMd(l.localeName);
    String dateLabel(DateTime? d) => d == null ? '-' : dateFmt.format(d);

    final pdfChip = savedInvoice == null
        ? InvoiceSummarySmallChip(
            label: l.invoicePdfNotGeneratedLabel,
            background: cs.surfaceContainerHighest,
            foreground: cs.onSurfaceVariant,
          )
        : InvoiceSummarySmallChip(
            label: l.invoicePdfGeneratedLabel,
            background: cs.tertiaryContainer,
            foreground: cs.onTertiaryContainer,
          );

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InvoiceSummaryHeader(invoiceNumber: invoiceNumber, status: status),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InvoiceSummaryInfoBox(
                  title: l.invoiceFromLabel,
                  value: issuerName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InvoiceSummaryInfoBox(
                  title: l.invoiceBillToLabel,
                  value: client?.name ?? l.invoiceSelectClientLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InvoiceSummaryInfoBox(
                  title: l.invoiceDateLabel,
                  value: dateLabel(invoiceDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InvoiceSummaryInfoBox(
                  title: l.invoiceDueDateLabel,
                  value: dateLabel(dueDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (notes.trim().isNotEmpty) ...[
            InvoiceSummaryInfoBox(title: l.invoiceNotesLabel, value: notes.trim()),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l.invoiceLinesTitle} (${lines.length})',
                  style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              pdfChip,
            ],
          ),
          const SizedBox(height: 12),
          InvoiceSummaryLinesAndTotals(
            lines: lines,
            subtotal: subtotal,
            tax: tax,
            total: total,
          ),
        ],
      ),
    );

    return Card(
      elevation: 1,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: fillHeight
          ? Column(
              children: [Expanded(child: SingleChildScrollView(child: content))],
            )
          : SingleChildScrollView(child: content),
    );
  }
}

