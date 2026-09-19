import 'package:flutter/widgets.dart';

extension BuildContextLocale on BuildContext {
  bool get isSpanishLocale =>
      Localizations.localeOf(this).languageCode.toLowerCase() == 'es';
}
