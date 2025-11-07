import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/token_store.dart';

class TokenService {
  static final TokenStore _store = SecureTokenStore();

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      _store.save(AuthTokens(access: accessToken, refresh: refreshToken));

  static Future<String?> loadToken() => _store.readAccess();
  static Future<String?> loadRefreshToken() => _store.readRefresh();
  static Future<AuthTokens?> loadBoth() => _store.readBoth();
  static Future<void> clearTokens() => _store.clear();
}
