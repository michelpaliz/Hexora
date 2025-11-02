import 'package:flutter/material.dart';

class AppColors {
  // 🩵 Surfaces & backgrounds
  static const Color background = Color(0xFFF9FAFB); // light neutral
  static const Color surface = Color(0xFFFFFFFF); // pure white

  // 🔷 Primary (Blue)
  static const Color primary = Color(0xFF1E88E5); // calmer blue
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);

  // 🟠 Secondary (Amber / Warm accent)
  static const Color secondary = Color(0xFFFFB74D);
  static const Color secondaryLight = Color(0xFFFFD180);
  static const Color secondaryDark = Color(0xFFF57C00);

  // ✍️ Text & icons
  static const Color textPrimary = Color(0xFF1B1F23);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color icon = primary;

  // Utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppDarkColors {
  // 🌙 Backgrounds
  static const Color background = Color(0xFF0F141A);
  static const Color surface = Color(0xFF1E1E24);

  // 🔷 Primary (Cool blue base)
  static const Color primary = Color(0xFF64B5F6);
  static const Color primaryLight = Color(0xFF90CAF9);
  static const Color primaryDark = Color(0xFF1976D2);

  // 🟠 Secondary (Warm amber accent)
  static const Color secondary = Color(0xFFFFB74D);
  static const Color secondaryLight = Color(0xFFFFCC80);

  // ✍️ Text & icons
  static const Color textPrimary = Color(0xFFFDFDFD);
  static const Color textSecondary = Color(0xFFB0BEC5);

  // ⚠️ Error
  static const Color error = Color(0xFFEF5350);
}
