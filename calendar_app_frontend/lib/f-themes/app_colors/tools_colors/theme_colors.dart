import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors.dart';

class ThemeColors {
  /// Returns theme-appropriate text color.
  static Color getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
  }

  /// Returns readable contrast text color for a given background.
  static Color getContrastTextColorForBackground(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static Color getContrastTextColor(BuildContext context, Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// Slightly lighter fill color for inputs.
  static Color getLighterInputFillColor(BuildContext context) {
    final base = getContainerBackgroundColor(context);
    final brightness = ThemeData.estimateBrightnessForColor(base);
    return brightness == Brightness.dark
        ? base.withOpacity(0.6)
        : base.withOpacity(0.95);
  }

  static Color getTextColorWhite(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppDarkColors.textPrimary
        : AppColors.primary;
  }

  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getContainerBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  // 🟦 Default button colors
  static Color getButtonBackgroundColor(BuildContext context,
      {bool isSecondary = false, bool isDanger = false}) {
    final theme = Theme.of(context);

    if (isDanger) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFFD32F2F)
          : const Color(0xFFE53935);
    }

    if (isSecondary) {
      return theme.brightness == Brightness.dark
          ? AppDarkColors.secondary
          : AppColors.secondary;
    }

    return theme.brightness == Brightness.dark
        ? AppDarkColors.primary
        : AppColors.primary;
  }

  static Color getButtonTextColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppDarkColors.textPrimary
        : AppColors.white;
  }

  static Color getSearchBarBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppDarkColors.surface
        : AppColors.surface.withOpacity(0.9);
  }

  static Color getSearchBarIconColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppDarkColors.secondary
        : AppColors.secondary;
  }

  static Color getSearchBarHintTextColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondary;
  }

  static Color getCardShadowColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.black54
        : Colors.black26;
  }

  static Color getListTileBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? AppDarkColors.surface
        : AppColors.white;
  }

  static Color getFilterChipGlowColor(BuildContext context, Color baseColor) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? baseColor.withOpacity(0.25)
        : _darkenColor(baseColor, 0.3);
  }

  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor().withOpacity(0.25);
  }
}
