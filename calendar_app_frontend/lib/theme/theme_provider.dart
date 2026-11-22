// theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LightThemeVariant { neutral, blue }

class ThemeModeProvider with ChangeNotifier {
  static const _key = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _lightVariantKey = 'light_theme_variant';
  ThemeMode _mode = ThemeMode.system;
  LightThemeVariant _lightVariant = LightThemeVariant.neutral;
  bool _loaded = false;

  ThemeModeProvider() {
    _init();
  }

  ThemeMode get mode => _mode;
  LightThemeVariant get lightVariant => _lightVariant;
  bool get isLoaded => _loaded;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      _mode = _stringToMode(raw) ?? ThemeMode.system;
      _lightVariant = _stringToLightVariant(
            prefs.getString(_lightVariantKey),
          ) ??
          LightThemeVariant.neutral;
    } catch (e) {
      // Web localStorage can be corrupted; fall back to defaults.
      _mode = ThemeMode.system;
      debugPrint('[ThemeModeProvider] prefs init failed: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setLightVariant(LightThemeVariant variant) async {
    if (_lightVariant == variant) return;
    _lightVariant = variant;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lightVariantKey, _lightVariantToString(variant));
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _modeToString(mode));
  }

  Future<void> toggleLightDark() async {
    final next = (_mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  // Helpers
  static String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode? _stringToMode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  static String _lightVariantToString(LightThemeVariant variant) =>
      variant == LightThemeVariant.blue ? 'blue' : 'neutral';

  static LightThemeVariant? _stringToLightVariant(String? value) {
    switch (value) {
      case 'blue':
        return LightThemeVariant.blue;
      case 'neutral':
        return LightThemeVariant.neutral;
      default:
        return null;
    }
  }
}
