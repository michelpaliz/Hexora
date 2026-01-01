import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class InvoiceSummarySmallChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const InvoiceSummarySmallChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: t.bodySmall
            .copyWith(color: foreground, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class InvoiceSummaryStatusChip extends StatelessWidget {
  final String status;
  const InvoiceSummaryStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final issued = normalized.contains('issue');

    final bg = issued ? cs.secondaryContainer : cs.surfaceContainerHighest;
    final fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Text(
        normalized.isEmpty ? 'draft' : normalized,
        style: t.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}

