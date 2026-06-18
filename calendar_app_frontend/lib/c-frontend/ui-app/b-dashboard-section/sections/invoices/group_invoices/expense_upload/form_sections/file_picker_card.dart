import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/prompt_clipboard_helper.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseFilePickerCard extends StatefulWidget {
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
  State<ExpenseFilePickerCard> createState() => _ExpenseFilePickerCardState();
}

class _ExpenseFilePickerCardState extends State<ExpenseFilePickerCard> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasFile = widget.fileName != null && widget.fileBytes != null;
    final lowerName = widget.fileName?.toLowerCase() ?? '';
    final isImage = lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.jpe');
    final isPdf = lowerName.endsWith('.pdf');
    final previewAction = hasFile
        ? isPdf
            ? widget.onPreviewPdf
            : isImage
                ? () => showExpenseImagePreviewDialog(
                      context,
                      fileName: widget.fileName!,
                      fileBytes: widget.fileBytes!,
                    )
                : null
        : null;

    final dropChild = Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: widget.dropZoneHeight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      cs.outlineVariant.withValues(alpha: hasFile ? 0.5 : 0.4),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasFile
                        ? _ExpenseFilePreview(
                            fileName: widget.fileName!,
                            fileBytes: widget.fileBytes!,
                            isImage: isImage,
                            isPdf: isPdf,
                            onPreview: previewAction,
                          )
                        : Column(
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
                                onPressed:
                                    widget.submitting ? null : widget.onPick,
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: Text(l.expenseUploadFileSelectCta),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.fileName ?? l.expenseUploadFileSelectPlaceholder,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    final content = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: widget.submitting ? null : widget.onPick,
      child: dropChild,
    );

    return content;
  }
}

class _ExpenseFilePreview extends StatelessWidget {
  final String fileName;
  final Uint8List fileBytes;
  final bool isImage;
  final bool isPdf;
  final VoidCallback? onPreview;

  const _ExpenseFilePreview({
    required this.fileName,
    required this.fileBytes,
    required this.isImage,
    required this.isPdf,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (isImage) {
      return Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColoredBox(
                color: cs.surface,
                child: Image.memory(
                  fileBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _PreviewActionButton(
              icon: Icons.zoom_in_rounded,
              tooltip: 'Abrir vista ampliada',
              onPressed: onPreview ??
                  () => showExpenseImagePreviewDialog(
                        context,
                        fileName: fileName,
                        fileBytes: fileBytes,
                      ),
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.insert_drive_file,
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
                if (isPdf && onPreview != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: Text(l.invoicePdfCta),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isPdf && onPreview != null)
          Positioned(
            top: 10,
            right: 10,
            child: _PreviewActionButton(
              icon: Icons.zoom_in_rounded,
              tooltip: 'Abrir PDF',
              onPressed: onPreview!,
            ),
          ),
      ],
    );
  }
}

Future<void> showExpenseImagePreviewDialog(
  BuildContext context, {
  required String fileName,
  required Uint8List fileBytes,
}) async {
  if (!canPresentUiOnContext(context)) return;
  final cs = Theme.of(context).colorScheme;
  final t = AppTypography.of(context);
  await showSafeDialogOnActiveView<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: cs.surface,
        child: SizedBox(
          width: 980,
          height: 760,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usa la rueda del raton o pellizca para hacer zoom.',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: ColoredBox(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.memory(
                          fileBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PreviewActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _PreviewActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surface.withValues(alpha: 0.88),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 16,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
