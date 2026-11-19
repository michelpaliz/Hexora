import 'compact_component_theme.dart';
// lib/theme/themes/light_theme.dart
import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/presentation/shared/widgets/app_bars/app_bar_styles.dart';

final ThemeData lightTheme = compactComponentTheme(ThemeData(
  fontFamily: HexoraTypography.fontFamily,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary, // blue base
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryDark,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: const Color(0xFFEEF3FA),
    surfaceContainerHigh: const Color(0xFFE8EFF8),
    surfaceContainerHighest: const Color(0xFFE1EAF6),
    outline: const Color(0xFF7A8BA5),
    outlineVariant: AppColors.outline,
    // keep your chosen secondary if you want the amber accent
    secondary: AppColors.secondary,
    onSecondary: ThemeData.estimateBrightnessForColor(AppColors.secondary) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xFF1B1F23),
  ),
  textTheme: AppTypography.materialTextTheme(
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: AppBarStyles.defaultAppBarTheme(),
  extensions: <ThemeExtension<dynamic>>[
    AppTypography.light(scale: 1.0),
  ],
));
