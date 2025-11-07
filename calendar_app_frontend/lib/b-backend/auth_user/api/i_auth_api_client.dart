/// Abstraction for auth HTTP calls.
/// Keeps `AuthProvider` clean and testable.
abstract class IAuthApiClient {
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> profile({
    required String accessToken,
  });

  Future<Map<String, dynamic>> refresh({
    required String refreshToken,
  });

  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });
}
