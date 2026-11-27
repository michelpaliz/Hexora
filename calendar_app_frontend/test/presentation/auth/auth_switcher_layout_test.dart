import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/repositories/auth_repository.dart';
import 'package:hexora/presentation/screens/auth/forgot_password.dart';
import 'package:hexora/presentation/screens/auth/login/form/login_form.dart';
import 'package:hexora/presentation/screens/auth/register/ui/form/register_form.dart';
import 'package:hexora/presentation/screens/auth/shared_utilities/auth_switcher_view.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoRequests extends Fake implements AuthRepository {}

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

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool register = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final locale = LocaleProvider(deviceLocale: const Locale('es'));
  addTearDown(locale.dispose);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthService(_NoRequests())),
      ChangeNotifierProvider.value(value: locale),
    ],
    child: Consumer<LocaleProvider>(
      builder: (context, currentLocale, child) => MaterialApp(
        theme:
            ThemeData(brightness: brightness, extensions: const [_typography]),
        locale: currentLocale.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: AuthSwitcherView(showRegister: register),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 800.0, 1200.0]) {
      testWidgets('auth is scrollable and responsive at $width in $brightness',
          (tester) async {
        await _pump(tester,
            size: Size(width, 640), brightness: brightness, textScale: 1.4);
        expect(find.byType(RegisterForm), findsOneWidget);
        expect(find.byType(HexoraWordmark),
            width >= 1000 ? findsOneWidget : findsNothing);
        expect(find.byType(HexoraBrandIcon),
            width < 1000 ? findsOneWidget : findsNothing);
        expect(
          tester.getSize(find.byKey(const ValueKey('auth-card'))).width,
          lessThanOrEqualTo(480),
        );
        expect(tester.takeException(), isNull);
        final submit = find.descendant(
            of: find.byType(RegisterForm),
            matching: find.byType(ElevatedButton));
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('news panel is visible to the left of login on wide screens',
      (tester) async {
    await _pump(
      tester,
      size: const Size(1200, 800),
      register: false,
    );

    final news = find.byKey(const ValueKey('auth-news-desktop'));
    final authCard = find.byKey(const ValueKey('auth-card'));
    expect(news, findsOneWidget);
    expect(
        find.byKey(const ValueKey('announcement-empty-state')), findsOneWidget);
    expect(
        tester.getTopRight(news).dx, lessThan(tester.getTopLeft(authCard).dx));
    expect(find.byKey(const ValueKey('auth-news-inline')), findsNothing);
  });

  testWidgets('account switch and recovery navigation work without duplicates',
      (tester) async {
    await _pump(tester);
    final switcher = find.byKey(const ValueKey('auth-mode-switch'));
    await tester.tap(
        find.descendant(of: switcher, matching: find.text('Iniciar sesión')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.byType(RegisterForm), findsNothing);
    final context = tester.element(find.byType(LoginForm));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.dontHaveAccount), findsNothing);
    await tester.tap(find.text(l10n.forgotPassword));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordForm), findsOneWidget);
    expect(switcher, findsNothing);
    await tester.tap(find.text(l10n.backToLogin));
    await tester.pumpAndSettle();
    expect(find.byType(LoginForm), findsOneWidget);
    expect(switcher, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'fields support autofill and retain input through responsive resize',
      (tester) async {
    await _pump(tester, register: false);
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].autofillHints, [AutofillHints.email]);
    expect(fields[0].textInputAction, TextInputAction.next);
    expect(fields[1].autofillHints, [AutofillHints.password]);
    expect(fields[0].decoration!.floatingLabelBehavior,
        FloatingLabelBehavior.always);
    await tester.enterText(
        find.byKey(const Key('login_email_field')), 'user@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .focusNode
            .hasFocus,
        isTrue);
    await tester.enterText(
        find.byKey(const Key('login_password_field')), 'password123');
    await tester.pump();
    final submit = find.byKey(const Key('login_submit_button'));
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('login_email_field')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'user@example.com',
    );
    tester.view.physicalSize = const Size(390, 600);
    await tester.pumpAndSettle();
    expect(find.byType(HexoraBrandIcon), findsOneWidget);
    expect(find.byType(HexoraWordmark), findsNothing);
    String fieldValue(Key key) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(EditableText),
          ),
        )
        .controller
        .text;
    expect(fieldValue(const Key('login_email_field')), 'user@example.com');
    expect(fieldValue(const Key('login_password_field')), 'password123');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('language switch preserves the active tab and entered values',
      (tester) async {
    await _pump(tester, register: false);
    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );

    await tester.tap(find.byKey(const ValueKey('auth-language-en')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('login_email_field')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'user@example.com',
    );

    await tester.tap(find.byKey(const ValueKey('auth-language-es')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
