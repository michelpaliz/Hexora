import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class InvoicePdfPreviewCard extends StatelessWidget {
  final Invoice? savedInvoice;
  final VoidCallback onPreviewPdf;

  const InvoicePdfPreviewCard({
    super.key,
    required this.savedInvoice,
    required this.onPreviewPdf,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final ready = savedInvoice != null;
    final subtitle = ready
        ? 'PDF is ready to preview'
        : 'Save draft to generate a PDF preview';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PDF preview',
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (ready)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Generated',
                      style: t.bodySmall.copyWith(
                        color: cs.onTertiaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (ready) ...[
                          const SizedBox(height: 4),
                          Text(
                            savedInvoice!.invoiceNumber,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPreviewPdf,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
