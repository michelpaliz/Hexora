import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class InvoiceJsonImportUnavailablePanel extends StatelessWidget {
  const InvoiceJsonImportUnavailablePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
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
      child: Text(
        'JSON import unavailable in this context.',
        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
