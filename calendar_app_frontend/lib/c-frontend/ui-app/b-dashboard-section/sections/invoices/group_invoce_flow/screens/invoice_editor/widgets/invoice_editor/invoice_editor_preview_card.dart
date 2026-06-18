import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceEditorPreviewCard extends StatelessWidget {
  final String invoiceNumber;
  final String notes;
  final int lineCount;
  final num total;
  final VoidCallback onPreviewPdf;

  const InvoiceEditorPreviewCard({
    super.key,
    required this.invoiceNumber,
    required this.notes,
    required this.lineCount,
    required this.total,
    required this.onPreviewPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.invoicePreviewTitle,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(invoiceNumber,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(notes.isEmpty ? l.invoicePreviewNoNotes : notes),
          const SizedBox(height: 8),
          Text(l.invoicePreviewLinesCount(lineCount)),
          const SizedBox(height: 8),
          Text(l.invoicePreviewTotalLabel(NumberFormat.simpleCurrency(name: '').format(total))),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onPreviewPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l.invoicePdfPreviewTitle),
          ),
        ],
      ),
    );
  }
}
