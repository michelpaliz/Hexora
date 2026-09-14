import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/register/utils/legal_text_helper.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  Widget buildSubject({
    String? termsUrl,
    String? privacyUrl,
    LegalLinkAction? onTermsTap,
    LegalLinkAction? onPrivacyTap,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LegalLinks(
          termsUrl: termsUrl,
          privacyUrl: privacyUrl,
          onTermsTap: onTermsTap,
          onPrivacyTap: onPrivacyTap,
        ),
      ),
    );
  }

  testWidgets('renders valid legal URLs as tappable links', (tester) async {
    Uri? openedTerms;
    Uri? openedPrivacy;
    await tester.pumpWidget(
      buildSubject(
        termsUrl: 'https://example.com/terms',
        privacyUrl: 'https://example.com/privacy',
        onTermsTap: (uri) async {
          openedTerms = uri;
          return true;
        },
        onPrivacyTap: (uri) async {
          openedPrivacy = uri;
          return true;
        },
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final children = (richText.text as TextSpan).children!;

    expect(children[1], isA<TextSpan>());
    expect((children[1] as TextSpan).recognizer, isA<TapGestureRecognizer>());
    expect(children[3], isA<TextSpan>());
    expect((children[3] as TextSpan).recognizer, isA<TapGestureRecognizer>());

    await tester.tap(find.text('Terms'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.pump();
    expect(openedTerms, Uri.parse('https://example.com/terms'));
    expect(openedPrivacy, Uri.parse('https://example.com/privacy'));
  });

  testWidgets('renders a localized fallback when legal URLs are unavailable',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        termsUrl: 'not a URL',
        privacyUrl: 'ftp://example.com/privacy',
      ),
    );

    expect(
      find.text('Terms and Privacy Policy are currently unavailable.'),
      findsOneWidget,
    );
  });
}
