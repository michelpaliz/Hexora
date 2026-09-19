import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es'); // ✅ Default is now Spanish

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('es'); // ✅ Also reset to Spanish
    notifyListeners();
  }
}
