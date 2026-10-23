import 'package:flutter/material.dart';

class AppColors {
  // ðŸ©µ Surfaces & backgrounds
  static const Color background = Color(0xFFF5F8FD);
  static const Color surface = Color(0xFFFFFFFF); // pure white
  static const Color formSection = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFEEF3FA);
  static const Color inputBorder = Color(0xFFD5E0EF);
  static const Color inputFocus = Color(0xFF2563EB);
  static const Color selectedControl = Color(0xFFDBEAFE);

  // ðŸ”· Primary (Blue)
  static const Color primary = Color(0xFF1760CF);
  static const Color primaryContainer = selectedControl;
  static const Color outline = inputBorder;
  static const Color navigationForeground = Color(0xFFF1F5FC);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color dashboardTopBar = Color(0xFF14263A);

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
  static const Color background = Color(0xFF0E1929);
  static const Color sidebar = Color(0xFF14263A);
  static const Color surface = Color(0xFF192B40);
  static const Color surfaceHover = Color(0xFF20344A);
  static const Color border = Color(0xFF30465D);

  // ðŸ”· Primary (Cool blue base)
  static const Color primary = Color(0xFF60A5FA);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color dashboardTopBar = sidebar;

  // ðŸŸ  Secondary (Warm amber accent)
  static const Color secondary = Color(0xFFFFB74D);
  static const Color secondaryLight = Color(0xFFFFCC80);

  // ✍️ Text & icons
  static const Color textPrimary = Color(0xFFE9F1FA);
  static const Color textSecondary = Color(0xFFAEBFD1);

  // ⚠️ Error
  static const Color error = Color(0xFFEF5350);
}
