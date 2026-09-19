// lib/theme/themes/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/app_bars/app_bar_styles.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppDarkColors.primary,
  scaffoldBackgroundColor: AppDarkColors.background,
  appBarTheme: AppBarStyles.defaultAppBarTheme(isDarkMode: true),
  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
  ).copyWith(
    primary: AppDarkColors.primary,
    secondary: AppDarkColors.secondary,
    surface: AppDarkColors.surface,
    onPrimary: AppDarkColors.background,
    onSecondary: AppDarkColors.background,
    error: AppDarkColors.error,
    onError: AppDarkColors.background,
    onSurface: AppDarkColors.textPrimary,
  ),
  textTheme: AppTypography.materialTextTheme(
    brightness: Brightness.dark,
  ),
  extensions: <ThemeExtension<dynamic>>[
    AppTypography.dark(scale: 0.98), // defined below
  ],
);
