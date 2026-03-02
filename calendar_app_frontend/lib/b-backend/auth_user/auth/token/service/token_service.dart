import 'dart:async';
import 'dart:convert';

import 'package:hexora/b-backend/auth_user/api/auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/token_store.dart';

class TokenService {
  static final TokenStore _store = SecureTokenStore();
  static final AuthApiClientImpl _authApi = AuthApiClientImpl();
  static Future<String?>? _refreshingToken;

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      _store.save(AuthTokens(access: accessToken, refresh: refreshToken));

  static Future<String?> loadToken() async {
    final access = await _store.readAccess();
    if (access == null || access.isEmpty) return null;

    // Non-JWT tokens are returned as-is.
    if (!_isJwt(access)) return access;

    // Refresh when token is already expired or close to expiry.
    if (!_isExpiredOrNearExpiry(access, thresholdSeconds: 60)) {
      return access;
    }

    final inFlight = _refreshingToken;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<String?>();
    _refreshingToken = completer.future;
    try {
      final refreshed = await _refreshAccessToken();
      completer.complete(refreshed);
      return refreshed;
    } catch (_) {
      completer.complete(access);
      return access;
    } finally {
      _refreshingToken = null;
    }
  }

  static Future<String?> loadRefreshToken() => _store.readRefresh();
  static Future<AuthTokens?> loadBoth() => _store.readBoth();
  static Future<void> clearTokens() => _store.clear();

  static bool _isJwt(String token) => token.split('.').length >= 2;

  static bool _isExpiredOrNearExpiry(
    String token, {
    int thresholdSeconds = 60,
  }) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      final payload = utf8.decode(base64Url.decode(_padBase64(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return false;
      final expRaw = decoded['exp'];
      final expSeconds = expRaw is int
          ? expRaw
          : (expRaw is String ? int.tryParse(expRaw) : null);
      if (expSeconds == null) return false;
      final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      return expSeconds <= (nowSeconds + thresholdSeconds);
    } catch (_) {
      return false;
    }
  }

  static String _padBase64(String input) {
    final normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    final pad = (4 - normalized.length % 4) % 4;
    return normalized + ('=' * pad);
  }

  static Future<String?> _refreshAccessToken() async {
    final refreshToken = await _store.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final data = await _authApi.refresh(refreshToken: refreshToken);
    final status = data['_status'] as int? ?? 200;
    if (status < 200 || status >= 300 || data['_error'] == true) {
      return null;
    }

    final newAccess =
        (data['accessToken'] ?? data['access_token'])?.toString().trim();
    if (newAccess == null || newAccess.isEmpty) return null;

    final newRefresh =
        (data['refreshToken'] ?? data['refresh_token'])?.toString().trim() ??
            refreshToken;
    await saveTokens(
      accessToken: newAccess,
      refreshToken: newRefresh,
    );
    return newAccess;
  }
}
