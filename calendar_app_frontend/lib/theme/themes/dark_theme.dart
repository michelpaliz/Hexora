import 'compact_component_theme.dart';
// lib/theme/themes/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/app_bars/app_bar_styles.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

final _darkScheme = ColorScheme.fromSeed(
  seedColor: AppDarkColors.primary,
  brightness: Brightness.dark,
).copyWith(
  primary: AppDarkColors.primary,
  onPrimary: AppDarkColors.background,
  primaryContainer: AppDarkColors.surfaceHover,
  onPrimaryContainer: AppDarkColors.textPrimary,
  secondary: AppDarkColors.secondary,
  onSecondary: AppDarkColors.background,
  surface: AppDarkColors.surface,
  onSurface: AppDarkColors.textPrimary,
  onSurfaceVariant: AppDarkColors.textSecondary,
  surfaceContainerLowest: AppDarkColors.background,
  surfaceContainerLow: AppDarkColors.surface,
  surfaceContainer: AppDarkColors.surface,
  surfaceContainerHigh: AppDarkColors.surfaceHover,
  surfaceContainerHighest: AppDarkColors.surfaceHover,
  outline: AppDarkColors.border,
  outlineVariant: AppDarkColors.border,
  error: AppDarkColors.error,
  onError: AppDarkColors.background,
);

final ThemeData darkTheme = compactComponentTheme(ThemeData(
  fontFamily: HexoraTypography.fontFamily,
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppDarkColors.primary,
  scaffoldBackgroundColor: AppDarkColors.background,
  appBarTheme: AppBarStyles.defaultAppBarTheme(isDarkMode: true),
  colorScheme: _darkScheme,
  cardTheme: CardThemeData(
    color: AppDarkColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppDarkColors.border),
    ),
  ),
  dividerColor: AppDarkColors.border,
  dialogTheme: const DialogThemeData(
    backgroundColor: AppDarkColors.surface,
    surfaceTintColor: Colors.transparent,
  ),
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: AppDarkColors.sidebar,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppDarkColors.border),
    ),
    textStyle: const TextStyle(color: AppDarkColors.textPrimary, fontSize: 12),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: AppDarkColors.surface,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppDarkColors.border),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppDarkColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppDarkColors.primary, width: 1.5),
    ),
  ),
  textTheme: AppTypography.materialTextTheme(
    brightness: Brightness.dark,
  ),
  extensions: <ThemeExtension<dynamic>>[
    AppTypography.dark(scale: 1.0), // defined below
  ],
));
