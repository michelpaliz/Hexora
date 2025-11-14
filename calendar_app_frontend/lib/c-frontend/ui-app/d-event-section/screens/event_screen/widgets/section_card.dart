import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

enum SectionCardStyle { elevated, outlined, filled }

class SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget>? children;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final SectionCardStyle style;
  final double radius;

  const SectionCard({
    super.key,
    this.title,
    this.children,
    this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.style = SectionCardStyle.elevated,
    this.radius = 16,
  }) : assert(children != null || child != null,
         'Provide either children or child');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typo = AppTypography.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Tints to avoid “white on white”
    final subtleTint = Color.alphaBlend(
      cs.primary.withOpacity(isDark ? 0.08 : 0.06),
      cs.surface,
    );
    final strongTint = Color.alphaBlend(
      cs.primary.withOpacity(isDark ? 0.14 : 0.10),
      cs.surface,
    );

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title!,
              style: typo.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
        if (children != null) ...children! else child!,
      ],
    );

    switch (style) {
      case SectionCardStyle.elevated:
        return Card(
          margin: margin,
          elevation: isDark ? 1.5 : 2.5,
          shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
          color: subtleTint,
          surfaceTintColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: cs.outlineVariant, width: 0.8),
          ),
          child: Padding(padding: padding, child: content),
        );

      case SectionCardStyle.outlined:
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: Padding(padding: padding, child: content),
        );

      case SectionCardStyle.filled:
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: strongTint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.outlineVariant, width: 0.8),
          ),
          child: Padding(padding: padding, child: content),
        );
    }
  }
}
