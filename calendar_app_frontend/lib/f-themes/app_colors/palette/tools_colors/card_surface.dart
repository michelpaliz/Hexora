import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/define_themes/mobile_theme.dart';

import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';

class CardSurface {
  static Color bg(BuildContext context) {
    if (MobileTheme.isActive(context)) {
      return Theme.of(context).colorScheme.surfaceContainerLow;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.surface : AppColors.surface.withOpacity(0.98);
  }

  static Color border(BuildContext context) {
    if (MobileTheme.isActive(context)) {
      return Theme.of(context).colorScheme.outlineVariant;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppDarkColors.textSecondary.withOpacity(0.14)
        : AppColors.primary.withOpacity(0.08);
  }

  static Color shadow(BuildContext context) {
    if (MobileTheme.isActive(context)) return Colors.transparent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.12);
  }

  static Color onBg(BuildContext context) {
    if (MobileTheme.isActive(context)) {
      return Theme.of(context).colorScheme.onSurface;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
  }

  static Color onBgSecondary(BuildContext context) {
    if (MobileTheme.isActive(context)) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
  }

  static Color softAccent(BuildContext context) {
    if (MobileTheme.isActive(context)) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppDarkColors.primary.withOpacity(0.10)
        : AppColors.primary.withOpacity(0.08);
  }
}

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
      constraints: BoxConstraints(minHeight: constrainedMinHeight ?? 0),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    return Card(
      margin: margin,
      elevation: MobileTheme.isActive(context) ? 0 : elevation,
      shadowColor: sh,
      color: bg,
      clipBehavior: clip,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(MobileTheme.isActive(context) ? 16 : radius),
        side: BorderSide(color: br, width: 1),
      ),
      child: content,
    );
  }
}
