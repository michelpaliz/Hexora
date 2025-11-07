import 'package:hexora/a-models/user_model/user.dart';

abstract class AuthRepository {
  User? get currentUser; // <- getter only (remove setter)

  Future<User?> logIn({required String email, required String password});
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logOut();
  Future<void> sendEmailVerification();
  Future<void> initialize();
  Future<User?> getCurrentUserModel();
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );
  Future<String?> getToken();
}
