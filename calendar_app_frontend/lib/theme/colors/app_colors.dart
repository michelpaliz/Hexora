import 'package:flutter/material.dart';

class AppColors {
  // ðŸ©µ Surfaces & backgrounds
  static const Color background = Color(0xFFF5F8FD);
  static const Color surface = Color(0xFFFFFFFF); // pure white

  // ðŸ”· Primary (Blue)
  static const Color primary = Color(0xFF1760CF);
  static const Color primaryContainer = Color(0xFFE6EFFF);
  static const Color outline = Color(0xFFDCE5F2);
  static const Color navigationForeground = Color(0xFFF1F5FC);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color dashboardTopBar = Color(0xFF152538);

  // ðŸŸ  Secondary (Amber / Warm accent)
  static const Color secondary = Color(0xFFFFB74D);
  static const Color secondaryLight = Color(0xFFFFD180);
  static const Color secondaryDark = Color(0xFFF57C00);

  // ✍️ Text & icons
  static const Color textPrimary = Color(0xFF142138);
  static const Color textSecondary = Color(0xFF586A86);

  static const Color icon = primary;

  // Utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppDarkColors {
  // ðŸŒ™ Backgrounds
  static const Color background = Color(0xFF0F141A);
  static const Color surface = Color(0xFF1E1E24);

  // ðŸ”· Primary (Cool blue base)
  static const Color primary = Color(0xFF64B5F6);
  static const Color primaryLight = Color(0xFF90CAF9);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color dashboardTopBar =
      Color(0xFF172235); // slightly lighter than background for depth

  // ðŸŸ  Secondary (Warm amber accent)
  static const Color secondary = Color(0xFFFFB74D);
  static const Color secondaryLight = Color(0xFFFFCC80);

  // ✍️ Text & icons
  static const Color textPrimary = Color(0xFFFDFDFD);
  static const Color textSecondary = Color(0xFFB0BEC5);

  // ⚠️ Error
  static const Color error = Color(0xFFEF5350);
}
