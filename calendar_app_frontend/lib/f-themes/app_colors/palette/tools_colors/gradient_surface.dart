// lib/f-themes/shape/gradients/gradient_surface.dart
import 'package:flutter/material.dart';

/// Reusable rounded gradient “surface” with optional border, padding, and margin.
/// Now defaults to **neutral greys** for an easy-on-the-eyes background.
class GradientSurface extends StatelessWidget {
  const GradientSurface({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,

    /// If you pass [colors], they will be used directly.
    /// Otherwise we use neutral tones when [useNeutral] is true (default),
    /// or the colorful primary↔tertiary look when [useNeutral] is false.
    this.colors,

    // Colorful (primary/tertiary) opacities (used only when useNeutral=false)
    this.primaryOpacity = 0.12,
    this.tertiaryOpacity = 0.10,
    this.border = true,

    /// Border opacity. With neutral mode we use outlineVariant;
    /// with colorful mode we use primary.
    this.borderOpacity = 0.12,

    /// When true (default), use neutral greys derived from the theme.
    this.useNeutral = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double radius;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  final List<Color>? colors;
  final double primaryOpacity;
  final double tertiaryOpacity;

  final bool border;
  final double borderOpacity;

  /// Toggle neutral greys vs colorful primary/tertiary.
  final bool useNeutral;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Neutral greys (soft, desaturated, theme-aware)
    final neutralStart = isDark
        ? cs.surfaceVariant.withOpacity(0.22)
        : cs.surfaceVariant.withOpacity(0.50);
    final neutralEnd =
        isDark ? cs.surface.withOpacity(0.32) : cs.surface.withOpacity(0.80);

    final resolvedColors = colors ??
        (useNeutral
            ? <Color>[neutralStart, neutralEnd]
            : <Color>[
                cs.primary.withOpacity(primaryOpacity),
                cs.tertiary.withOpacity(tertiaryOpacity),
              ]);

    final borderColor = useNeutral
        ? cs.outlineVariant.withOpacity(borderOpacity)
        : cs.primary.withOpacity(borderOpacity);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient:
            LinearGradient(begin: begin, end: end, colors: resolvedColors),
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: borderColor) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  /// Convenience: neutral greys (surfaceVariant → surface), subtle border.
  factory GradientSurface.neutral({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 16,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    bool border = true,
    double borderOpacity = 0.12,
  }) {
    return GradientSurface(
      key: key,
      child: child,
      margin: margin,
      padding: padding,
      radius: radius,
      begin: begin,
      end: end,
      border: border,
      borderOpacity: borderOpacity,
      useNeutral: true,
    );
  }

  /// Convenience: uses *container* tones (primaryContainer → tertiaryContainer).
  /// This is the more colorful panel look you already used elsewhere.
  factory GradientSurface.containerTones({
    Key? key,
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 16,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double c1Opacity = 0.35,
    double c2Opacity = 0.35,
    bool border = true,
    double borderOpacity = 0.08,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GradientSurface(
      key: key,
      child: child,
      margin: margin,
      padding: padding,
      radius: radius,
      begin: begin,
      end: end,
      colors: [
        cs.primaryContainer.withOpacity(c1Opacity),
        cs.tertiaryContainer.withOpacity(c2Opacity),
      ],
      border: border,
      borderOpacity: borderOpacity,
      useNeutral: false, // explicitly colorful
    );
  }
}
