import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/auth/verify_email/verify_email_view.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/repositories/auth_repository.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  String? resentTo;

  @override
  Future<void> resendVerificationEmail({
    required String email,
    String? invitationToken,
  }) async {
    resentTo = email;
  }
}

const _typography = AppTypography(
  displayLarge: TextStyle(fontSize: 32),
  displayMedium: TextStyle(fontSize: 28),
  titleLarge: TextStyle(fontSize: 22),
  bodyLarge: TextStyle(fontSize: 16),
  bodyMedium: TextStyle(fontSize: 14),
  bodySmall: TextStyle(fontSize: 12),
  buttonText: TextStyle(fontSize: 16),
  caption: TextStyle(fontSize: 12),
  accentHeading: TextStyle(fontSize: 20),
  accentText: TextStyle(fontSize: 16),
);

Future<_FakeAuthRepository> _pump(
  WidgetTester tester, {
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final repository = _FakeAuthRepository();
  final locale = LocaleProvider(deviceLocale: const Locale('es'));
  addTearDown(locale.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(repository)),
        ChangeNotifierProvider.value(value: locale),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, currentLocale, child) => MaterialApp(
          theme: ThemeData(extensions: const [_typography]),
          locale: currentLocale.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VerifyEmailView(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [Size(390, 640), Size(1200, 800)]) {
    testWidgets('verification view follows the responsive auth shell at $size',
        (tester) async {
      await _pump(tester, size: size);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(HexoraWordmark),
          size.width >= 1000 ? findsOneWidget : findsNothing);
      expect(find.byType(HexoraBrandIcon),
          size.width < 1000 ? findsOneWidget : findsNothing);
      expect(find.byKey(const Key('verify_email_title')), findsOneWidget);
      expect(find.byKey(const Key('verify_email_field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('resend action keeps the entered email', (tester) async {
    final repository = await _pump(tester, size: const Size(1200, 800));

    await tester.enterText(
      find.byKey(const Key('verify_email_field')),
      'user@example.com',
    );
    await tester.tap(find.byKey(const Key('resend_verification_button')));
    await tester.pumpAndSettle();

    expect(repository.resentTo, 'user@example.com');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
