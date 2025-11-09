import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';

// ^ adjust this import to wherever AppColors/AppDarkColors live

/// Centralized palette for cards that adapts to light & dark using your AppColors.
class CardSurface {
  /// Background color for cards.
  static Color bg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use your surface with a hair of translucency in light for softness
    return isDark ? AppDarkColors.surface : AppColors.surface.withOpacity(0.98);
  }

  /// Border color for subtle outlines.
  static Color border(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Tie the outline subtly to primary in light; neutral in dark
    return isDark
        ? AppDarkColors.textSecondary.withOpacity(0.14)
        : AppColors.primary.withOpacity(0.08);
  }

  /// Shadow color for elevation feel.
  static Color shadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Softer, shorter shadow in dark; a tad stronger in light
    return isDark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.12);
  }

  /// Default foreground (text/icon) for cards.
  static Color onBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
  }

  /// Secondary foreground (subtitles, meta text).
  static Color onBgSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
  }

  /// Accent strip / chip background on cards (very subtle).
  static Color softAccent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppDarkColors.primary.withOpacity(0.10)
        : AppColors.primary.withOpacity(0.08);
  }
}

/// Drop-in card with sane defaults from [CardSurface].
class ThemedCard extends StatelessWidget {
  const ThemedCard({
    super.key,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.radius = 12,
    this.elevation = 1.0,
    this.clip = Clip.antiAlias,
    this.child,
    this.constrainedMinHeight,
  });

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double elevation;
  final Clip clip;
  final Widget? child;
  final double? constrainedMinHeight;

  @override
  Widget build(BuildContext context) {
    final bg = CardSurface.bg(context);
    final br = CardSurface.border(context);
    final sh = CardSurface.shadow(context);

    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: constrainedMinHeight ?? 0,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    return Card(
      margin: margin,
      elevation: elevation,
      shadowColor: sh,
      color: bg,
      clipBehavior: clip,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: br, width: 1),
      ),
      child: content,
    );
  }
}
