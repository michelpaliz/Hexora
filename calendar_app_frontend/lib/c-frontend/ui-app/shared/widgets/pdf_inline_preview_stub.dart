import 'dart:typed_data';
import 'package:flutter/material.dart';

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
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        'PDF preview is only available on web.',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
