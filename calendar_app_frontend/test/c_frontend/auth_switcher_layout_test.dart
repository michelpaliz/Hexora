import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/repositories/auth_repository.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/forgot_password.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/login/form/login_form.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/register/ui/form/register_form.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/shared_utilities/auth_switcher_view.dart';
import 'package:hexora/c-frontend/utils/logo/hexora_brand.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
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
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => AuthService(_NoRequests()),
    child: MaterialApp(
      theme: ThemeData(brightness: brightness, extensions: const [_typography]),
      locale: const Locale('es'),
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
        expect(tester.getSize(find.byType(Card)).width, lessThanOrEqualTo(480));
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
    tester.view.physicalSize = const Size(390, 600);
    await tester.pumpAndSettle();
    expect(find.byType(HexoraBrandIcon), findsOneWidget);
    expect(find.byType(HexoraWordmark), findsNothing);
    final resized =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(resized[0].controller!.text, 'user@example.com');
    expect(resized[1].controller!.text, 'password123');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
