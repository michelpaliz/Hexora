import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double titleSpacing;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.titleSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: titleSpacing),
          DefaultTextStyle(
            style: t.bodyMedium.copyWith(color: cs.onSurface),
            child: child,
          ),
        ],
      ),
    );
  }
}
