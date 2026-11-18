import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es'); // ✅ Default is now Spanish

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    AuthenticatedHttpClient.setPreferredLanguage(locale.languageCode);
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('es'); // ✅ Also reset to Spanish
    AuthenticatedHttpClient.setPreferredLanguage('es');
    notifyListeners();
  }
}
