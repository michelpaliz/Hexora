import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class StatementsAllDataTableClientCell extends StatelessWidget {
  const StatementsAllDataTableClientCell({
    super.key,
    required this.label,
    required this.unlinked,
  });

  final String label;
  final bool unlinked;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (!unlinked) {
      return Text(label, style: typography.bodyMedium);
    }
    return Text(
      label,
      style: typography.bodySmall.copyWith(color: cs.onSurfaceVariant),
      overflow: TextOverflow.ellipsis,
    );
  }
}
