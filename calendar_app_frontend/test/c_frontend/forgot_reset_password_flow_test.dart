import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/models/verification_result.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/b-backend/auth_user/repositories/auth_repository.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/forgot_password.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/reset_password/reset_password_screen.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/l10n.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepository implements AuthRepository {
  Future<void> Function(String email)? onForgotPassword;
  Future<void> Function({required String token, required String newPassword})?
      onResetPassword;

  int forgotCalls = 0;
  int resetCalls = 0;

  @override
  User? get currentUser => null;

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<String> createUser({
    required String name,
    required String userName,
    required String email,
    required String password,
  }) async =>
      'ok';

  @override
  Future<void> forgotPassword(String email) async {
    forgotCalls += 1;
    final fn = onForgotPassword;
    if (fn != null) await fn(email);
  }

  @override
  Future<User?> getCurrentUserModel() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<User?> logIn(
          {required String email, required String password}) async =>
      null;

  @override
  Future<void> logOut() async {}

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    resetCalls += 1;
    final fn = onResetPassword;
    if (fn != null) {
      await fn(token: token, newPassword: newPassword);
    }
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<VerificationResult> verifyEmailToken({required String token}) async =>
      const VerificationResult(success: true, message: 'ok');
}

Widget _testApp(Widget child, _FakeAuthRepository repo) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(repo),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('forgot-password valid submit -> success state', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(_testApp(const ForgotPasswordForm(), repo));

    await tester.enterText(
        find.byKey(const Key('forgot_email_field')), 'user@example.com');
    await tester.tap(find.byKey(const Key('forgot_submit_button')));
    await tester.pumpAndSettle();

    expect(repo.forgotCalls, 1);
    expect(find.byKey(const Key('forgot_success_message')), findsOneWidget);
  });

  testWidgets('forgot-password invalid email validation', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(_testApp(const ForgotPasswordForm(), repo));

    await tester.enterText(
        find.byKey(const Key('forgot_email_field')), 'bad-email');
    await tester.tap(find.byKey(const Key('forgot_submit_button')));
    await tester.pumpAndSettle();

    expect(repo.forgotCalls, 0);
    expect(find.text('This is an invalid email address'), findsOneWidget);
  });

  testWidgets('reset-password missing token screen state', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(_testApp(const ResetPasswordScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reset_invalid_link_state')), findsOneWidget);
  });

  testWidgets('reset-password mismatch validation', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(
        _testApp(const ResetPasswordScreen(initialToken: 't1'), repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('reset_new_password_field')), '12345678');
    await tester.enterText(
        find.byKey(const Key('reset_confirm_password_field')), '12345679');
    await tester.tap(find.byKey(const Key('reset_submit_button')));
    await tester.pumpAndSettle();

    expect(repo.resetCalls, 0);
    expect(find.text('New password and confirmation password do not match.'),
        findsOneWidget);
  });

  testWidgets('reset-password success flow', (tester) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(
        _testApp(const ResetPasswordScreen(initialToken: 't1'), repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('reset_new_password_field')), '12345678');
    await tester.enterText(
        find.byKey(const Key('reset_confirm_password_field')), '12345678');
    await tester.tap(find.byKey(const Key('reset_submit_button')));
    await tester.pumpAndSettle();

    expect(repo.resetCalls, 1);
    expect(find.byKey(const Key('reset_success_state')), findsOneWidget);
  });

  testWidgets('reset-password invalid/expired token API error', (tester) async {
    final repo = _FakeAuthRepository()
      ..onResetPassword =
          ({required String token, required String newPassword}) async {
        throw ResetPasswordInvalidOrExpiredTokenException(
            'Invalid or expired token');
      };
    await tester.pumpWidget(
        _testApp(const ResetPasswordScreen(initialToken: 't1'), repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('reset_new_password_field')), '12345678');
    await tester.enterText(
        find.byKey(const Key('reset_confirm_password_field')), '12345678');
    await tester.tap(find.byKey(const Key('reset_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reset_api_error')), findsOneWidget);
    expect(
        find.byKey(const Key('reset_request_new_link_button')), findsOneWidget);
  });
}
