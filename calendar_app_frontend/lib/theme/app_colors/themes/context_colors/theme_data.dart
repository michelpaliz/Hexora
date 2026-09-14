// lib/theme/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:hexora/theme/app_colors/themes/context_colors/define_themes/dark_theme.dart';
import 'package:hexora/theme/app_colors/themes/context_colors/define_themes/light_theme.dart';

class AppTheme {
  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;

  // Optional: choose from Brightness
  static ThemeData fromBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;
}
