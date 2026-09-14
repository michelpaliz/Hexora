import 'package:flutter/material.dart';

enum SectionSurfaceStyle { elevated, outlined, filled }

class SectionSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final SectionSurfaceStyle style;
  final double radius;

  const SectionSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.style = SectionSurfaceStyle.elevated,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // visible tint over surface to avoid white-on-white
    final subtleTint = Color.alphaBlend(
      cs.primary.withOpacity(isDark ? 0.08 : 0.06),
      cs.surface,
    );
    final strongTint = Color.alphaBlend(
      cs.primary.withOpacity(isDark ? 0.14 : 0.10),
      cs.surface,
    );

    switch (style) {
      case SectionSurfaceStyle.elevated:
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
          child: Padding(padding: padding, child: child),
        );

      case SectionSurfaceStyle.outlined:
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surface, // base surface, but with outline
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: Padding(padding: padding, child: child),
        );

      case SectionSurfaceStyle.filled:
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: strongTint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.outlineVariant, width: 0.8),
          ),
          child: Padding(padding: padding, child: child),
        );
    }
  }
}
