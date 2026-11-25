import 'dart:async';

import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/user/user_preferences_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _localeKey = 'preferred_locale';
  static const _migrationOwnerKey = 'locale_preferences_migration_owner';
  static const defaultLocale = Locale('es');
  Locale _locale = defaultLocale;
  String? _userId;
  int _loadVersion = 0;
  late final Future<void> _initialLoad;

  LocaleProvider() {
    _initialLoad = _init();
  }

  Locale get locale => _locale;

  Future<void> _init() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_localeKey);
      if (stored != null && (stored == 'en' || stored == 'es')) {
        _applyLocale(Locale(stored));
      }
    } catch (error) {
      debugPrint('[LocaleProvider] local load failed: $error');
    }
  }

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
      final languageCode = remote['locale'];
      final preferences = await SharedPreferences.getInstance();
      if (languageCode == 'en' || languageCode == 'es') {
        _applyLocale(Locale(languageCode as String));
        await preferences.setString(_keyFor(nextUserId), languageCode);
      } else {
        final migrationOwner = preferences.getString(_migrationOwnerKey);
        final canMigrate = migrationOwner == null;
        final stored = preferences.getString(_keyFor(nextUserId));
        final legacy = canMigrate ? preferences.getString(_localeKey) : null;
        final selected = _isSupportedCode(stored)
            ? stored!
            : _isSupportedCode(legacy)
                ? legacy!
                : defaultLocale.languageCode;
        _applyLocale(Locale(selected));
        await preferences.setString(_keyFor(nextUserId), selected);
        if (canMigrate) {
          await preferences.setString(_migrationOwnerKey, nextUserId);
        }
        await UserPreferencesApi.update({'locale': selected});
      }
    } catch (error) {
      debugPrint('[LocaleProvider] remote load failed: $error');
    }
  }

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _applyLocale(locale);
    unawaited(_persistLocale(locale.languageCode));
  }

  void _applyLocale(Locale locale) {
    _locale = locale;
    AuthenticatedHttpClient.setPreferredLanguage(locale.languageCode);
    notifyListeners();
  }

  Future<void> _persistLocale(String languageCode) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final currentUserId = _userId;
      await preferences.setString(
        currentUserId == null ? _localeKey : _keyFor(currentUserId),
        languageCode,
      );
      if (_userId != null) {
        await UserPreferencesApi.update({'locale': languageCode});
      }
    } catch (error) {
      debugPrint('[LocaleProvider] save failed: $error');
    }
  }

  void clearLocale() {
    _userId = null;
    _loadVersion++;
    _applyLocale(defaultLocale);
  }

  static bool _isSupportedCode(String? value) => value == 'en' || value == 'es';

  static String _keyFor(String userId) => 'hexora.user.$userId.$_localeKey';
}
