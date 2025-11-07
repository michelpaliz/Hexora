import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors.dart';

/// Semantic color helpers that respect ThemeMode and your palette.
/// Prefers Theme.of(context).colorScheme; falls back to your palette where helpful.
class ThemeColors {
  ThemeColors._();

  /// Generic contrast for any background color.
  static Color contrastOn(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// Theme-aware text color (primary body text).
  static Color textPrimary(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.onBackground;
  }

  /// In dark mode: normal text; in light: a white-ish choice suitable on primary.
  static Color textOnPrimaryPref(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.onBackground
        : theme.colorScheme.onPrimary;
  }

  /// Surfaces
  static Color containerBg(BuildContext context) =>
      Theme.of(context).colorScheme.background;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Slightly lighter fill for inputs placed on container backgrounds.
  static Color inputFillLighter(BuildContext context) {
    final base = containerBg(context);
    final isDark =
        ThemeData.estimateBrightnessForColor(base) == Brightness.dark;
    return isDark ? base.withOpacity(0.6) : base.withOpacity(0.95);
  }

  /// Shadows
  static Color cardShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black54
          : Colors.black26;

  /// ListTile backgrounds
  static Color listTileBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : AppColors.white;

  /// Search bar pieces
  static Color searchBg(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : theme.colorScheme.surface.withOpacity(0.9);
  }

  static Color searchIcon(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppDarkColors.secondary
          : AppColors.secondary;

  static Color searchHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppDarkColors.textSecondary
          : AppColors.textSecondary;

  /// Filter chip glow: subtle in dark, darker tone in light.
  static Color chipGlow(BuildContext context, Color base) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? base.withOpacity(0.25)
        : _darken(base, 0.3).withOpacity(0.25);
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  // Add this inside ThemeColors
  static Color textSecondary(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Prefer Material's secondary text token
    final materialSecondary = cs.onSurfaceVariant;

    // If onSurfaceVariant looks identical to onBackground (some themes),
    // derive a softer secondary from onBackground.
    final derived = cs.onBackground.withOpacity(
      theme.brightness == Brightness.dark ? 0.85 : 0.72,
    );

    // Palette fallback (keeps your brand colors)
    final paletteFallback = theme.brightness == Brightness.dark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondary;

    // Choose the best option in order: material → derived → palette
    // (If your cs.onSurfaceVariant is well tuned, it'll be used.)
    if (materialSecondary.value != cs.onBackground.value) {
      return materialSecondary;
    }
    return derived.opacity == 0 ? paletteFallback : derived;
  }
}
