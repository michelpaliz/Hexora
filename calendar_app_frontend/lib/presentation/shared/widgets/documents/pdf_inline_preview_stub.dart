import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

/// Native PDF rendering shared by expenses, invoices, receipts and quotes.
class PdfInlinePreview extends StatelessWidget {
  const PdfInlinePreview({
    super.key,
    required this.bytes,
    this.height = 420,
    this.interactive = true,
  });

  final Uint8List bytes;
  final double height;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IgnorePointer(
          ignoring: !interactive,
          child: PdfViewer.data(
            bytes,
            // A replacement document must not reuse the previous PDF cache.
            sourceName: 'preview-${identityHashCode(bytes)}.pdf',
            key: ObjectKey(bytes),
            params: PdfViewerParams(
              backgroundColor: cs.surfaceContainerHighest,
              loadingBannerBuilder: (_, __, ___) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorBannerBuilder: (context, error, stack, document) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.invoicePdfPreviewFailedSnack,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
