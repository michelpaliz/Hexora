import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/build_context_locale.dart';

void main() {
  testWidgets('identifies Spanish locales by language code', (tester) async {
    bool? isSpanish;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('es', 'ES'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            isSpanish = context.isSpanishLocale;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(isSpanish, isTrue);
  });

  testWidgets('does not classify non-Spanish locales as Spanish',
      (tester) async {
    bool? isSpanish;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            isSpanish = context.isSpanishLocale;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(isSpanish, isFalse);
  });
}
