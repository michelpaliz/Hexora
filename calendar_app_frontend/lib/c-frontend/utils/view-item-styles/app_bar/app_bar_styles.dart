import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:flutter/material.dart';

class AppBarStyles {
  static AppBarTheme defaultAppBarTheme({bool isDarkMode = false}) {
    return AppBarTheme(
      // Use primary blue in light mode, and its darker counterpart in dark mode
      color: isDarkMode ? AppDarkColors.primary : AppColors.primary,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        fontFamily: 'Lato',
      ),
      iconTheme: const IconThemeData(
        color: Colors.white, // back arrow & icons
      ),
      foregroundColor: Colors.white, // text & icon tint
    );
  }
}
