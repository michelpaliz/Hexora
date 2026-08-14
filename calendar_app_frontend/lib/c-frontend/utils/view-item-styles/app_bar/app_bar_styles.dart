import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class AppBarStyles {
  static AppBarTheme defaultAppBarTheme({bool isDarkMode = false}) {
    final titleStyle = AppTypography.materialTextTheme(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
    ).titleLarge;
    return AppBarTheme(
      // Use primary blue in light mode, and its darker counterpart in dark mode
      backgroundColor: isDarkMode ? AppDarkColors.primary : AppColors.primary,
      centerTitle: true,
      titleTextStyle: titleStyle?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white, // back arrow & icons
      ),
      foregroundColor: Colors.white, // text & icon tint
    );
  }
}
