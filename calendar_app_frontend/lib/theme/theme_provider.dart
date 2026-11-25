// theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:hexora/services/user/user_preferences_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LightThemeVariant { neutral, blue }

class ThemeModeProvider with ChangeNotifier {
  static const _key = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _lightVariantKey = 'light_theme_variant';
  static const _migrationOwnerKey = 'theme_preferences_migration_owner';
  static const defaultMode = ThemeMode.light;
  static const defaultLightVariant = LightThemeVariant.neutral;
  ThemeMode _mode = defaultMode;
  LightThemeVariant _lightVariant = defaultLightVariant;
  bool _loaded = false;
  String? _userId;
  int _loadVersion = 0;
  late final Future<void> _initialLoad;

  ThemeModeProvider() {
    _initialLoad = _init();
  }

  ThemeMode get mode => _mode;
  LightThemeVariant get lightVariant => _lightVariant;
  bool get isLoaded => _loaded;

  Future<void> bindUser(String? userId) async {
    final normalized = userId?.trim();
    final nextUserId =
        normalized == null || normalized.isEmpty ? null : normalized;
    if (_userId == nextUserId) return;
    _userId = nextUserId;
    final version = ++_loadVersion;
    if (nextUserId == null) return;

    await _initialLoad;
    try {
      final remote = await UserPreferencesApi.load();
      if (version != _loadVersion) return;
      final remoteMode = _stringToMode(remote['themeMode'] as String?);
      final remoteVariant =
          _stringToLightVariant(remote['lightThemeVariant'] as String?);
      final prefs = await SharedPreferences.getInstance();
      final migrationOwner = prefs.getString(_migrationOwnerKey);
      final canMigrate = migrationOwner == null;
      if (remoteMode != null) {
        _mode = remoteMode;
      } else {
        _mode = _stringToMode(prefs.getString(_keyFor(nextUserId))) ??
            (canMigrate ? _mode : defaultMode);
      }
      if (remoteVariant != null) {
        _lightVariant = remoteVariant;
      } else {
        _lightVariant = _stringToLightVariant(
              prefs.getString(_variantKeyFor(nextUserId)),
            ) ??
            (canMigrate ? _lightVariant : defaultLightVariant);
      }
      await prefs.setString(_keyFor(nextUserId), _modeToString(_mode));
      await prefs.setString(
        _variantKeyFor(nextUserId),
        _lightVariantToString(_lightVariant),
      );
      if (canMigrate) {
        await prefs.setString(_migrationOwnerKey, nextUserId);
      }
      if (remoteMode == null || remoteVariant == null) {
        await UserPreferencesApi.update({
          if (remoteMode == null) 'themeMode': _modeToString(_mode),
          if (remoteVariant == null)
            'lightThemeVariant': _lightVariantToString(_lightVariant),
        });
      }
      notifyListeners();
    } catch (error) {
      debugPrint('[ThemeModeProvider] remote load failed: $error');
    }
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      _mode = _stringToMode(raw) ?? defaultMode;
      _lightVariant = _stringToLightVariant(
            prefs.getString(_lightVariantKey),
          ) ??
          defaultLightVariant;
    } catch (e) {
      // Web localStorage can be corrupted; fall back to defaults.
      _mode = defaultMode;
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
    final currentUserId = _userId;
    await prefs.setString(
      currentUserId == null ? _lightVariantKey : _variantKeyFor(currentUserId),
      _lightVariantToString(variant),
    );
    if (currentUserId != null) {
      try {
        await UserPreferencesApi.update({
          'lightThemeVariant': _lightVariantToString(variant),
        });
      } catch (error) {
        debugPrint('[ThemeModeProvider] remote save failed: $error');
      }
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = _userId;
    await prefs.setString(
      currentUserId == null ? _key : _keyFor(currentUserId),
      _modeToString(mode),
    );
    if (currentUserId != null) {
      try {
        await UserPreferencesApi.update({'themeMode': _modeToString(mode)});
      } catch (error) {
        debugPrint('[ThemeModeProvider] remote save failed: $error');
      }
    }
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

  static String _keyFor(String userId) => 'hexora.user.$userId.$_key';

  static String _variantKeyFor(String userId) =>
      'hexora.user.$userId.$_lightVariantKey';
}
