import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizationsMethods {
  final Locale locale;

  AppLocalizationsMethods(this.locale);

  static AppLocalizationsMethods? of(BuildContext context) {
    final currentLanguage = AppLocalizations.of(context)?.language ?? 'en';
    return Localizations.of<AppLocalizationsMethods>(
          context,
          AppLocalizationsMethods,
        ) ??
        AppLocalizationsMethods(Locale(currentLanguage));
  }

  static const LocalizationsDelegate<AppLocalizationsMethods> delegate =
      _AppLocalizationsDelegate();

  String get currentLanguage => locale.languageCode;

  String formatDate(DateTime date) {
    return DateFormat('EEE, MMM d', currentLanguage).format(date);
  }

  String formatHours(DateTime date) {
    return DateFormat('hh:mm a', currentLanguage).format(date);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizationsMethods> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizationsMethods> load(Locale locale) async {
    return AppLocalizationsMethods(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) {
    return false;
  }
}
