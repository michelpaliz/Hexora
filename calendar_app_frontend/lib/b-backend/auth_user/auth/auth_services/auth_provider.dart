import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
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

  // Internal, centralized state writer
  void _setCurrentUser(User? user) {
    _user = user;
    _authStateController.add(_user);
    notifyListeners();
  }

  Stream<User?> get authStateStream => _authStateController.stream;

  String? get lastToken => _authToken;

  @override
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final res =
        await _authApi.register(name: name, email: email, password: password);
    final status = res['_status'] as int? ?? 201;
    if (status == 201) return 'User created successfully';

    final errorMessage = (res['message']?.toString() ?? '').toLowerCase();
    if (errorMessage.contains('email') && errorMessage.contains('already')) {
      throw EmailAlreadyUseAuthException();
    } else if (errorMessage.contains('weak') ||
        errorMessage.contains('password')) {
      throw WeakPasswordException();
    } else if (errorMessage.contains('invalid') &&
        errorMessage.contains('email')) {
      throw InvalidEmailAuthException();
    }
    throw GenericAuthException();
  }

  // LOGIN
  @override
  Future<User?> logIn({required String email, required String password}) async {
    final data = await _authApi.login(email: email, password: password);

    final status = data['_status'] as int? ?? 200;
    if (status != 200) {
      final msg = data['message']?.toString() ?? 'Login failed';
      throw Exception(msg);
    }

    final String? accessToken =
        (data['accessToken'] ?? data['access_token']) as String?;
    final String? refreshToken =
        (data['refreshToken'] ?? data['refresh_token']) as String?;
    final String? userId = (data['userId'] ?? data['id']) as String?;

    if (accessToken == null || refreshToken == null || userId == null) {
      throw FormatException('Missing required fields in login response');
    }

    _authToken = accessToken;

    // save via injected store
    await _tokens.save(AuthTokens(access: accessToken, refresh: refreshToken));

    final user = await _userRepo.getUserById(userId);
    _setCurrentUser(user);
    return _user;
  }

  @override
  Future<void> logOut() async {
    _authToken = null;
    await _tokens.clear();
    _setCurrentUser(null);
  }

  @override
  Future<void> sendEmailVerification() async {
    throw UnimplementedError('Handled by backend or removed entirely.');
  }

  // STARTUP
  @override
  Future<void> initialize() async {
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

    await _authApi.changePassword(
      accessToken: _authToken!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<String?> getToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) return _authToken;
    final stored = await _tokens.readAccess();
    if (stored != null && stored.isNotEmpty) {
      _authToken = stored;
      return stored;
    }
    return null;
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
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
