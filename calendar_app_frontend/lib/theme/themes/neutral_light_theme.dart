import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/app_bars/app_bar_styles.dart';
import 'package:hexora/theme/themes/compact_component_theme.dart';
import 'package:hexora/theme/themes/theme_variant.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

/// The default light palette: bright neutral surfaces with Hexora blue kept
/// as an action/accent color instead of tinting every surface blue.
final ThemeData neutralLightTheme = compactComponentTheme(
  ThemeData(
    fontFamily: HexoraTypography.fontFamily,
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE7EEFF),
      onPrimaryContainer: Color(0xFF123B8C),
      secondary: Color(0xFF64748B),
      onSecondary: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF172033),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF8FAFC),
      surfaceContainer: Color(0xFFF1F5F9),
      surfaceContainerHigh: Color(0xFFE8EEF5),
      surfaceContainerHighest: Color(0xFFDDE5EF),
      onSurfaceVariant: Color(0xFF526173),
      outline: Color(0xFF8B99AA),
      outlineVariant: Color(0xFFD7DEE8),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
    ),
    textTheme: AppTypography.materialTextTheme(brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: AppBarStyles.defaultAppBarTheme(),
    extensions: <ThemeExtension<dynamic>>[
      AppTypography.light(scale: 1.0),
      const HexoraThemeVariant(neutralLight: true),
    ],
  ),
);
