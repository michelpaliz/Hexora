import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_flow.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoicePhotoExtractPanel extends StatelessWidget {
  const InvoicePhotoExtractPanel({
    super.key,
    required this.state,
    required this.controller,
    required this.hasImagePreview,
    required this.onPreviewImage,
    required this.onPickImage,
    required this.onApply,
    required this.onClear,
  });

  final InvoiceLinesOcrFlowState? state;
  final InvoiceEditorController? controller;
  final bool hasImagePreview;
  final Future<void> Function()? onPreviewImage;
  final Future<void> Function()? onPickImage;
  final VoidCallback? onApply;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final current = state;
    final stage = current?.stage ?? OcrExtractionStage.idle;
    final extracting = stage == OcrExtractionStage.extracting;
    final extracted = current?.extractedLines ?? const [];
    final warnings = current?.warnings ?? const <String>[];
    final diagnostics = current?.diagnostics ?? const <String>[];
    final methodUsed = (current?.methodUsed ?? '').trim();
    final hasData = extracted.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.invoiceLinesPhotoTitle,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l.invoiceLinesPhotoSubtitle,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: extracting ? null : onPickImage,
                icon: extracting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_camera_outlined),
                label: Text(
                  extracting ? l.invoiceLinesPhotoExtracting : l.addPhoto,
                ),
              ),
              if (hasImagePreview) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onPreviewImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l.preview),
                ),
              ],
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: hasData ? onApply : null,
                icon: const Icon(Icons.playlist_add_check),
                label: Text(l.invoiceLinesPhotoApply),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: hasData ? onClear : null,
                icon: const Icon(Icons.clear_all),
                label: Text(l.invoiceLinesPhotoClear),
              ),
            ],
          ),
          if (current?.extractionError != null &&
              current!.extractionError!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              current.extractionError!,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '- $warning',
                  style: t.bodySmall.copyWith(color: cs.tertiary),
                ),
              ),
            ),
          ],
          if (methodUsed.isNotEmpty || diagnostics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cs.surface.withValues(alpha: 0.65),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (methodUsed.isNotEmpty)
                    Text(
                      'methodUsed: $methodUsed',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (diagnostics.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...diagnostics.take(6).map(
                      (diag) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '- $diag',
                          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (hasData) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.invoiceLinesPhotoExtractedCount(extracted.length.toString()),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add row',
                  onPressed: controller?.addOcrExtractedLine,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: extracted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final line = extracted[i];
                  final descCtrl = TextEditingController(text: line.description);
                  final qtyCtrl =
                      TextEditingController(text: line.quantity.toString());
                  final unitCtrl = TextEditingController(
                    text: line.unitPrice.toStringAsFixed(2),
                  );
                  final taxCtrl = TextEditingController(
                    text: line.taxRate.toStringAsFixed(2),
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: descCtrl,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => controller?.updateOcrExtractedLineField(
                                  i,
                                  description: v,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: qtyCtrl,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'Qty',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) =>
                                          controller?.updateOcrExtractedLineField(
                                        i,
                                        quantity: double.tryParse(
                                          v.replaceAll(',', '.'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextField(
                                      controller: unitCtrl,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'Unit',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) =>
                                          controller?.updateOcrExtractedLineField(
                                        i,
                                        unitPrice: double.tryParse(
                                          v.replaceAll(',', '.'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextField(
                                      controller: taxCtrl,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'Tax %',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) =>
                                          controller?.updateOcrExtractedLineField(
                                        i,
                                        taxRate: double.tryParse(
                                          v.replaceAll(',', '.'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            Text(
                              NumberFormat.simpleCurrency(name: '')
                                  .format(line.lineTotal),
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: controller == null
                                  ? null
                                  : () => controller!.removeOcrExtractedLine(i),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
