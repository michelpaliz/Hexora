import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/email_verification_state.dart';
import 'package:hexora/b-backend/auth_user/auth/models/verification_result.dart';
import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/b-backend/auth_user/repositories/auth_repository.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';

class AuthProvider extends ChangeNotifier implements AuthRepository {
  final IUserRepository _userRepo;
  final IAuthApiClient _authApi;
  final TokenStore _tokens; // injected token store

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  User? _user;
  String? _authToken;
  String? _pendingVerificationEmail;
  bool _requiresEmailVerification = false;

  AuthProvider({
    required IUserRepository userRepository,
    required IAuthApiClient authApi,
    required TokenStore tokens,
  })  : _userRepo = userRepository,
        _authApi = authApi,
        _tokens = tokens;

  // Getter-only per AuthRepository
  @override
  User? get currentUser => _user;

  String? get pendingVerificationEmail => _pendingVerificationEmail;
  bool get requiresEmailVerification => _requiresEmailVerification;

  // Internal, centralized state writer
  void _setCurrentUser(User? user) {
    _user = user;
    _authStateController.add(_user);
    notifyListeners();
  }

  Stream<User?> get authStateStream => _authStateController.stream;

  @Deprecated('Use getToken() to avoid stale in-memory token reads.')
  String? get lastToken => _authToken;

  @override
  Future<String> createUser({
    required String name,
    required String userName,
    required String email,
    required String password,
  }) async {
    final res = await _authApi.register(
      name: name,
      userName: userName,
      email: email,
      password: password,
    );
    final status = res['_status'] as int? ?? 201;
    if (status == 201) return 'User created successfully';

    final errorMessage = (res['message']?.toString() ?? '').toLowerCase();
    if (errorMessage.contains('username') && errorMessage.contains('already')) {
      throw UsernameAlreadyUseAuthException();
    } else if (errorMessage.contains('username') &&
        (errorMessage.contains('required') ||
            errorMessage.contains('missing'))) {
      throw Exception('Username is required');
    } else if (errorMessage.contains('email') &&
        errorMessage.contains('already')) {
      throw EmailAlreadyUseAuthException();
    } else if (errorMessage.contains('weak') ||
        errorMessage.contains('password')) {
      throw WeakPasswordException();
    } else if (errorMessage.contains('invalid') &&
        errorMessage.contains('email')) {
      throw InvalidEmailAuthException();
    }
    throw Exception(
        res['message']?.toString() ?? GenericAuthException().toString());
  }

  // LOGIN
  @override
  Future<User?> logIn({required String email, required String password}) async {
    await _clearVerificationState();
    final normalizedEmail = email.trim().toLowerCase();
    final data = await _authApi.login(
      email: normalizedEmail,
      password: password,
    );

    final status = data['_status'] as int? ?? 200;
    final message = _loginMessage(data);
    final emailNotVerified =
        status == 403 && _containsEmailNotVerifiedMessage(data);

    if (emailNotVerified) {
      _pendingVerificationEmail = normalizedEmail;
      _requiresEmailVerification = true;
      _logLoginDiagnostic(status, message, 'emailVerificationRequired');
      throw EmailNotVerifiedAuthException(message);
    } else if (status == 401) {
      _logLoginDiagnostic(status, message, 'invalidCredentials');
      throw WrongPasswordAuthException();
    } else if (status == 404) {
      _logLoginDiagnostic(status, message, 'userNotFound');
      throw UserNotFoundAuthException();
    } else if (status != 200) {
      _logLoginDiagnostic(status, message, 'genericLoginError');
      throw LoginRequestFailedAuthException(
        message.isNotEmpty ? message : 'Login failed',
        statusCode: status,
      );
    }

    await _clearVerificationState();

    final accessToken =
        (data['accessToken'] ?? data['access_token'])?.toString().trim();
    final refreshToken =
        (data['refreshToken'] ?? data['refresh_token'])?.toString().trim();
    final userId = (data['userId'] ?? data['id'])?.toString().trim();

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      _logLoginDiagnostic(status, message, 'invalidLoginResponse');
      throw const FormatException('Missing required fields in login response');
    }

    // Remove the previous session before publishing the newly issued pair.
    await _tokens.clear();
    await _tokens.save(AuthTokens(access: accessToken, refresh: refreshToken));
    _authToken = accessToken;

    try {
      final user = await _userRepo.getUserById(userId);
      _setCurrentUser(user);
      _logLoginDiagnostic(status, message, 'authenticated');
      return _user;
    } catch (_) {
      _authToken = null;
      await _tokens.clear();
      _setCurrentUser(null);
      rethrow;
    }
  }

  @override
  Future<void> logOut() async {
    _authToken = null;
    await _tokens.clear();
    await _clearVerificationState();
    _setCurrentUser(null);
  }

  @override
  Future<void> sendEmailVerification() async {
    if (_user == null) throw UserNotSignedInException();
    await resendVerificationEmail(email: _user!.email);
  }

  // STARTUP
  @override
  Future<void> initialize() async {
    await _clearVerificationState();
    _authToken = await _tokens.readAccess();

    if (_authToken == null) {
      notifyListeners();
      return;
    }

    final prof = await _authApi.profile(accessToken: _authToken!);
    final status = prof['_status'] as int? ?? 200;

    if (status == 200) {
      _setCurrentUser(User.fromJson(prof));
    } else if (status == 401) {
      final refreshed = await _tryRefreshToken();
      if (!refreshed) _setCurrentUser(null);
    }

    // notifyListeners() already called inside _setCurrentUser when it runs
    if (status != 200 && status != 401) notifyListeners();
  }

  String _loginMessage(Map<String, dynamic> data) {
    for (final key in const ['message', 'error']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'true') return value;
    }
    return '';
  }

  bool _containsEmailNotVerifiedMessage(Map<String, dynamic> data) {
    return const ['error', 'message'].any((key) {
      final value = data[key]?.toString().toLowerCase() ?? '';
      return value.contains('email not verified');
    });
  }

  Future<void> _clearVerificationState() async {
    _pendingVerificationEmail = null;
    _requiresEmailVerification = false;
    await EmailVerificationState.clearPersisted();
  }

  void _logLoginDiagnostic(int status, String message, String uiState) {
    if (!kDebugMode) return;
    final safeMessage = message.isEmpty ? '(empty)' : message;
    debugPrint(
      '[Auth][login] status=$status backendMessage=$safeMessage '
      'uiState=$uiState',
    );
  }

  @override
  Future<User?> getCurrentUserModel() async => _user;

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword != confirmPassword) throw PasswordMismatchException();
    if (_authToken == null) throw UserNotSignedInException();

    try {
      await _authApi.changePassword(
        accessToken: _authToken!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      final raw = e.toString();
      final statusMatch = RegExp(r'HTTP\s+(\d{3})').firstMatch(raw);
      final status = int.tryParse(statusMatch?.group(1) ?? '');
      final messageMatch = RegExp(r'HTTP\s+\d{3}\s*:\s*(.*)$').firstMatch(raw);
      final message = (messageMatch?.group(1) ?? raw).trim();
      final loweredMessage = message.toLowerCase();

      if (status == 401 &&
          loweredMessage.contains('current password') &&
          loweredMessage.contains('incorrect')) {
        throw CurrentPasswordMismatchException();
      }
      if (status == 400 &&
          (loweredMessage.contains('at least 8') ||
              (loweredMessage.contains('different') &&
                  loweredMessage.contains('current password')))) {
        throw ChangePasswordValidationException(message);
      }
      throw ChangePasswordRequestFailedException(
        message.isNotEmpty
            ? message
            : 'Failed to change password. Please try again.',
      );
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    final normalized = email.trim().toLowerCase();
    final res = await _authApi.forgotPassword(email: normalized);
    final status = res['_status'] as int? ?? 200;
    if (status >= 200 && status < 300) {
      return;
    }
    final message = res['message']?.toString().trim();
    throw ForgotPasswordRequestFailedException(
      message?.isNotEmpty == true
          ? message!
          : 'Failed to send reset link. Please try again.',
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await _authApi.resetPassword(
      token: token.trim(),
      newPassword: newPassword,
    );
    final status = res['_status'] as int? ?? 200;
    if (status >= 200 && status < 300) {
      return;
    }

    final message = res['message']?.toString().trim() ?? '';
    final lowered = message.toLowerCase();
    if (status == 400 &&
        (lowered.contains('token') ||
            lowered.contains('expired') ||
            lowered.contains('invalid'))) {
      throw ResetPasswordInvalidOrExpiredTokenException(
        message.isNotEmpty ? message : 'Invalid or expired reset token.',
      );
    }
    throw ResetPasswordRequestFailedException(
      message.isNotEmpty
          ? message
          : 'Failed to reset password. Please try again.',
    );
  }

  @override
  Future<String?> getToken() async {
    // Always prefer TokenService so expiry/refresh is handled consistently
    // across all feature repositories that depend on AuthService/AuthProvider.
    final valid = await TokenService.loadToken();
    if (valid != null && valid.isNotEmpty) {
      _authToken = valid;
      return valid;
    }

    // Fallback to raw store read for non-JWT/custom tokens.
    final stored = await _tokens.readAccess();
    if (stored != null && stored.isNotEmpty) {
      _authToken = stored;
      return stored;
    }
    return null;
  }

  Future<bool> setAutoStatementImportEnabled(bool enabled) async {
    if (_authToken == null) throw UserNotSignedInException();
    final updated =
        await _userRepo.setAutoStatementImportEnabled(enabled: enabled);
    if (_user != null) {
      _setCurrentUser(
        _user!.copyWith(autoStatementImportEnabled: updated),
      );
    }
    return updated;
  }

  // REFRESH
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokens.readRefresh();
    if (refreshToken == null) return false;

    final data = await _authApi.refresh(refreshToken: refreshToken);
    final status = data['_status'] as int? ?? 200;
    if (status != 200) return false;

    _authToken = ((data['accessToken'] ?? data['access_token']) as String?);
    if (_authToken == null) return false;

    final rotatedRefresh =
        (data['refreshToken'] ?? data['refresh_token']) as String? ??
            refreshToken;

    await _tokens.save(
      AuthTokens(access: _authToken!, refresh: rotatedRefresh),
    );

    final prof = await _authApi.profile(accessToken: _authToken!);
    if ((prof['_status'] as int? ?? 200) == 200) {
      _setCurrentUser(User.fromJson(prof));
    }

    return true;
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    final res =
        await _authApi.resendVerification(email: email.trim().toLowerCase());
    final status = res['_status'] as int? ?? 200;
    if (status != 200) {
      final msg =
          res['message']?.toString() ?? 'Unable to resend verification email.';
      throw Exception(msg);
    }
  }

  @override
  Future<VerificationResult> verifyEmailToken({required String token}) async {
    final res = await _authApi.verifyEmail(token: token);
    final status = res['_status'] as int? ?? 200;
    final message = res['message']?.toString() ?? 'Email verified';
    final success = status >= 200 && status < 300 && (res['_error'] != true);
    if (success) return VerificationResult(success: true, message: message);
    return VerificationResult(
      success: false,
      message: message.isNotEmpty ? message : 'Verification failed.',
    );
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
