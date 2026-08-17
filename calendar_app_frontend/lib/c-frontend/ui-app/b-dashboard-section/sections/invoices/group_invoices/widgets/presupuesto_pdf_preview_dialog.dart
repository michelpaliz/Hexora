import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';

/// Full-screen in-app preview for a generated presupuesto PDF. Rendering is
/// delegated to [PdfInlinePreview] (blob-backed iframe on web), so no bytes
/// are ever written to disk unless [onDownload] is invoked explicitly.
class PresupuestoPdfPreviewDialog extends StatelessWidget {
  const PresupuestoPdfPreviewDialog({
    super.key,
    required this.bytes,
    required this.onDownload,
  });

  final Uint8List bytes;
  final VoidCallback onDownload;

  static Future<void> show(
    BuildContext context, {
    required Uint8List bytes,
    required VoidCallback onDownload,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          PresupuestoPdfPreviewDialog(bytes: bytes, onDownload: onDownload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 720;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: isWide
          ? const EdgeInsets.symmetric(horizontal: 48, vertical: 32)
          : const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: isWide ? 880 : double.infinity,
        height: isWide
            ? (size.height - 64).clamp(400.0, 960.0)
            : size.height - 20,
        child: Column(
          children: [
            Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Vista previa del PDF',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: onDownload,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Descargar'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ColoredBox(
                color: cs.surfaceContainerLowest,
                child: PdfInlinePreview(bytes: bytes, height: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
