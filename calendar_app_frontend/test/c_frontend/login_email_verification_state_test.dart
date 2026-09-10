import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/email_verification_state.dart';
import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/login/form/login_form.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

class _FakeAuthApi implements IAuthApiClient {
  _FakeAuthApi(this.loginResponse);

  final Map<String, dynamic> loginResponse;
  String? submittedEmail;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    submittedEmail = email;
    return loginResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserRepository implements IUserRepository {
  _FakeUserRepository(this.user);

  final User user;

  @override
  Future<User> getUserById(String id) async => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryTokenStore implements TokenStore {
  AuthTokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<String?> readAccess() async => tokens?.access;

  @override
  Future<AuthTokens?> readBoth() async => tokens;

  @override
  Future<String?> readRefresh() async => tokens?.refresh;

  @override
  Future<void> save(AuthTokens tokens) async => this.tokens = tokens;
}

User _user({bool emailVerified = true}) => User(
      id: 'user-1',
      name: 'Michel Paliz',
      email: 'michelpaliz@hotmail.com',
      userName: 'michelp',
      groupIds: const [],
      emailVerified: emailVerified,
    );

AuthService _authService(
  Map<String, dynamic> response, {
  _FakeAuthApi? api,
  _MemoryTokenStore? tokens,
  User? user,
}) {
  final provider = AuthProvider(
    userRepository: _FakeUserRepository(user ?? _user()),
    authApi: api ?? _FakeAuthApi(response),
    tokens: tokens ?? _MemoryTokenStore(),
  );
  return AuthService(provider);
}

Widget _loginApp(AuthService authService) {
  return ChangeNotifierProvider<AuthService>.value(
    value: authService,
    child: MaterialApp(
      theme: ThemeData(extensions: const [_typography]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SingleChildScrollView(child: LoginForm())),
    ),
  );
}

Future<void> _submitLogin(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login_email_field')),
    'michelpaliz@hotmail.com',
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    'not-a-real-password',
  );
  await tester.pump();
  final submitButton = find.byKey(const Key('login_submit_button'));
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('HTTP 200 clears stale verification state and completes login',
      () async {
    SharedPreferences.setMockInitialValues({
      EmailVerificationState.pendingVerificationEmailKey: 'old@example.com',
      EmailVerificationState.requiresEmailVerificationKey: true,
    });
    final api = _FakeAuthApi({
      '_status': 200,
      'accessToken': 'new-access',
      'refreshToken': 'new-refresh',
      'userId': 'user-1',
    });
    final tokens = _MemoryTokenStore()
      ..tokens = const AuthTokens(access: 'old-access', refresh: 'old-refresh');
    final provider = AuthProvider(
      userRepository: _FakeUserRepository(
        // A stale/incomplete profile flag must not override a successful login.
        _user(emailVerified: false),
      ),
      authApi: api,
      tokens: tokens,
    );
    final auth = AuthService(provider);

    final loggedIn = await auth.logIn(
      email: '  MICHELPALIZ@HOTMAIL.COM ',
      password: 'secret',
    );

    final preferences = await SharedPreferences.getInstance();
    expect(loggedIn?.id, 'user-1');
    expect(auth.currentUser?.id, 'user-1');
    expect(provider.currentUser?.id, 'user-1');
    expect(provider.pendingVerificationEmail, isNull);
    expect(provider.requiresEmailVerification, isFalse);
    expect(api.submittedEmail, 'michelpaliz@hotmail.com');
    expect(tokens.tokens?.access, 'new-access');
    expect(tokens.tokens?.refresh, 'new-refresh');
    expect(
      preferences
          .containsKey(EmailVerificationState.pendingVerificationEmailKey),
      isFalse,
    );
    expect(
      preferences
          .containsKey(EmailVerificationState.requiresEmailVerificationKey),
      isFalse,
    );
  });

  testWidgets('HTTP 403 Email not verified opens verification UI',
      (tester) async {
    final auth = _authService({
      '_status': 403,
      'message': 'Email not verified',
    });
    await tester.pumpWidget(_loginApp(auth));

    await _submitLogin(tester);

    expect(find.byKey(const Key('email_verification_prompt')), findsOneWidget);
  });

  testWidgets('HTTP 401 Invalid credentials shows credentials error',
      (tester) async {
    final auth = _authService({
      '_status': 401,
      'message': 'Invalid credentials',
    });
    await tester.pumpWidget(_loginApp(auth));

    await _submitLogin(tester);

    expect(find.text('Invalid credentials. Please try again.'), findsOneWidget);
    expect(find.byKey(const Key('email_verification_prompt')), findsNothing);
  });

  testWidgets('unrelated HTTP 403 does not open verification UI',
      (tester) async {
    final auth = _authService({
      '_status': 403,
      'message': 'Account access is disabled',
    });
    await tester.pumpWidget(_loginApp(auth));

    await _submitLogin(tester);

    expect(
        find.text('Login failed: Account access is disabled'), findsOneWidget);
    expect(find.byKey(const Key('email_verification_prompt')), findsNothing);
  });

  testWidgets('stale stored verification data does not display prompt',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      EmailVerificationState.pendingVerificationEmailKey: 'old@example.com',
      EmailVerificationState.requiresEmailVerificationKey: true,
    });
    await tester.pumpWidget(_loginApp(_authService(const {})));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(find.byKey(const Key('email_verification_prompt')), findsNothing);
    expect(
      preferences
          .containsKey(EmailVerificationState.pendingVerificationEmailKey),
      isFalse,
    );
    expect(
      preferences
          .containsKey(EmailVerificationState.requiresEmailVerificationKey),
      isFalse,
    );
  });

  test('logout clears tokens, cached user, and verification state', () async {
    final tokens = _MemoryTokenStore();
    final provider = AuthProvider(
      userRepository: _FakeUserRepository(_user()),
      authApi: _FakeAuthApi({
        '_status': 200,
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'userId': 'user-1',
      }),
      tokens: tokens,
    );
    final auth = AuthService(provider);
    await auth.logIn(email: 'michelpaliz@hotmail.com', password: 'secret');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      EmailVerificationState.pendingVerificationEmailKey,
      'old@example.com',
    );
    await preferences.setBool(
      EmailVerificationState.requiresEmailVerificationKey,
      true,
    );

    await auth.logOut();

    expect(tokens.tokens, isNull);
    expect(provider.currentUser, isNull);
    expect(auth.currentUser, isNull);
    expect(provider.pendingVerificationEmail, isNull);
    expect(provider.requiresEmailVerification, isFalse);
    expect(
      preferences
          .containsKey(EmailVerificationState.pendingVerificationEmailKey),
      isFalse,
    );
    expect(
      preferences
          .containsKey(EmailVerificationState.requiresEmailVerificationKey),
      isFalse,
    );
  });
}
