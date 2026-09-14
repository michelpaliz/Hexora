// lib/theme/themes/light_theme.dart
import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/presentation/shared/widgets/app_bars/app_bar_styles.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary, // blue base
    brightness: Brightness.light,
  ).copyWith(
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
    AppTypography.light(scale: 0.98),
  ],
);
