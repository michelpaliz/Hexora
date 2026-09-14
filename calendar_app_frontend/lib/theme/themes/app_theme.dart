// lib/theme/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'mobile_theme.dart';
import 'package:hexora/theme/themes/dark_theme.dart';
import 'package:hexora/theme/themes/light_theme.dart';

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
