import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/models/verification_result.dart';

abstract class AuthRepository {
  User? get currentUser; // <- getter only (remove setter)

  Future<User?> logIn({required String email, required String password});
  Future<String> createUser({
    required String name,
    required String userName,
    required String email,
    required String password,
  });
  Future<void> logOut();
  Future<void> sendEmailVerification();
  Future<void> resendVerificationEmail({required String email});
  Future<VerificationResult> verifyEmailToken({required String token});
  Future<void> initialize();
  Future<User?> getCurrentUserModel();
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );
  Future<String?> getToken();
}
