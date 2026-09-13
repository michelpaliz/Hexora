// lib/f-themes/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'define_themes/mobile_theme.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/define_themes/dark_theme.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/define_themes/light_theme.dart';

class AppTheme {
  static ThemeData get light => forPlatform(Brightness.light);
  static ThemeData get dark => forPlatform(Brightness.dark);

  static final ThemeData _mobileLight = MobileTheme.build(lightTheme);
  static final ThemeData _mobileDark = MobileTheme.build(darkTheme);

  static ThemeData forPlatform(
    Brightness brightness, {
    TargetPlatform? platform,
    bool isWeb = kIsWeb,
  }) {
    final target = platform ?? defaultTargetPlatform;
    final mobile = !isWeb &&
        (target == TargetPlatform.android || target == TargetPlatform.iOS);
    if (brightness == Brightness.dark) {
      return mobile ? _mobileDark : darkTheme;
    }
    return mobile ? _mobileLight : lightTheme;
  }

  // Optional: choose from Brightness
  static ThemeData fromBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;
}
