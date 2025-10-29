// lib/f-themes/themes/light_theme.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_utilities/view-item-styles/app_bar/app_bar_styles.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: AppBarStyles.defaultAppBarTheme(),
  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onSurface: AppColors.textPrimary,
  ),
  // Attach your custom text styles as a ThemeExtension
  extensions: <ThemeExtension<dynamic>>[
    AppTypography.light(scale: 0.98), // defined below
  ],
);
