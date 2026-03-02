import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseFilePickerCard extends StatelessWidget {
  final String? fileName;
  final Uint8List? fileBytes;
  final bool submitting;
  final VoidCallback onPick;
  final VoidCallback? onPreviewPdf;
  final double dropZoneHeight;

  const ExpenseFilePickerCard({
    super.key,
    required this.fileName,
    required this.fileBytes,
    required this.submitting,
    required this.onPick,
    this.onPreviewPdf,
    this.dropZoneHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasFile = fileName != null && fileBytes != null;
    final lowerName = fileName?.toLowerCase() ?? '';
    final isImage = lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg');
    final isPdf = lowerName.endsWith('.pdf');

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: submitting ? null : onPick,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: dropZoneHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                    style: hasFile ? BorderStyle.solid : BorderStyle.none,
                  ),
                ),
                child: hasFile
                    ? _ExpenseFilePreview(
                        fileName: fileName!,
                        fileBytes: fileBytes!,
                        isImage: isImage,
                        isPdf: isPdf,
                        onPreviewPdf: onPreviewPdf,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 32,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.expenseUploadFileDropHint,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.expenseUploadFileOrLabel,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: submitting ? null : onPick,
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: Text(l.expenseUploadFileSelectCta),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fileName ?? l.expenseUploadFileSelectPlaceholder,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseFilePreview extends StatelessWidget {
  final String fileName;
  final Uint8List fileBytes;
  final bool isImage;
  final bool isPdf;
  final VoidCallback? onPreviewPdf;

  const _ExpenseFilePreview({
    required this.fileName,
    required this.fileBytes,
    required this.isImage,
    required this.isPdf,
    required this.onPreviewPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: cs.surface,
          child: Image.memory(
            fileBytes,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file,
              size: 36,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            if (isPdf && onPreviewPdf != null) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onPreviewPdf,
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(l.invoicePdfCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
