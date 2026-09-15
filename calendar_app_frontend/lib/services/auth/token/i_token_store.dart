import 'package:hexora/services/auth/token/token_obj.dart';

/// Abstraction for testability
abstract class TokenStore {
  Future<void> save(AuthTokens tokens);
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<AuthTokens?> readBoth();
  Future<void> clear();
}
