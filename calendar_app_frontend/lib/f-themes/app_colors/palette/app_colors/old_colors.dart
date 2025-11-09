

import 'package:flutter/material.dart';

class AppColors {
  // Background & surfaces
  static const Color background = Color(0xFFF5F5F5); // soft grey
  static const Color surface = Color(0xFFFFFFFF); // pure white

  // Primary blue (for icons, highlights, actions)
  static const Color primary = Color(0xFF2196F3); // Blue500
  static const Color primaryLight = Color(0xFF64B5F6); // Blue300
  static const Color primaryDark = Color(0xFF1976D2); // Blue700

  // Secondary (optional accents)
  static const Color secondary = Color(0xFF03A9F4); // LightBlue500
  static const Color secondaryLight = Color(0xFF67DAFF); // LightBlue300
  static const Color secondaryDark = Color(0xFF007AC1); // LightBlue700

  // Text & icons
  static const Color textPrimary =
      Color(0xFF212121); // Dark grey for readability
  static const Color textSecondary =
      Color(0xFF757575); // Medium grey for less emphasis
  static const Color icon = primary; // Icons use the brand blue

  // Utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppDarkColors {
  // Dark theme background & surfaces
  static const Color background = Color(0xFF121212); // deep black
  static const Color surface = Color(0xFF1E1E1E); // lighter grey

  // Primary blue stays bright against dark background
  static const Color primary = Color(0xFF2196F3); // Blue500
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);

  // Secondary accent
  static const Color secondary = Color(0xFF03A9F4);
  static const Color secondaryLight = Color(0xFF67DAFF);

  // Text & icons
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3E5FC);

  // Error
  static const Color error = Color(0xFFCF6679);
}
