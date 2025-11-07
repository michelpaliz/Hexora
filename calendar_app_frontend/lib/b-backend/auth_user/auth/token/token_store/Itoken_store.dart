import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';

/// Abstraction for testability
abstract class TokenStore {
  Future<void> save(AuthTokens tokens);
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<AuthTokens?> readBoth();
  Future<void> clear();
}
