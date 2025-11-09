import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart'; // import your palette
import 'package:flutter/material.dart';

class AppBarStyles {
  static AppBarTheme defaultAppBarTheme({bool isDarkMode = false}) {
    return AppBarTheme(
      // Primary blue for light, darker primary for dark mode
      color: isDarkMode ? AppDarkColors.primaryDark : AppColors.primary,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        fontFamily: 'Lato',
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      foregroundColor: Colors.white,
    );
  }
}
