import 'package:hexora/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class AppBarStyles {
  static AppBarTheme defaultAppBarTheme({bool isDarkMode = false}) {
    final titleStyle = AppTypography.materialTextTheme(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
    ).titleLarge;
    return AppBarTheme(
      // Use primary blue in light mode, and its darker counterpart in dark mode
      backgroundColor:
          isDarkMode ? AppDarkColors.dashboardTopBar : AppColors.primary,
      centerTitle: true,
      titleTextStyle: titleStyle?.copyWith(
        color: isDarkMode ? AppDarkColors.textPrimary : Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(
        color: isDarkMode ? AppDarkColors.textPrimary : Colors.white,
      ),
      foregroundColor: isDarkMode ? AppDarkColors.textPrimary : Colors.white,
    );
  }
}
