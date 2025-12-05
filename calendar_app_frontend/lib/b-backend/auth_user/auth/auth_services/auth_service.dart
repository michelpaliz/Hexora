import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/models/verification_result.dart';
import 'package:hexora/b-backend/auth_user/repositories/auth_repository.dart';

class AuthService with ChangeNotifier implements AuthRepository {
  final AuthRepository _repo;
  User? _user;

  AuthService(this._repo);

  @override
  User? get currentUser => _user;

  // Not an @override anymore (interface is getter-only)
  set currentUser(User? user) {
    if (user?.id != _user?.id) {
      _user = user;
      notifyListeners();
    }
  }

  @override
  Future<void> initialize() =>
      _repo.initialize().then((_) => currentUser = _repo.currentUser);

  @override
  Future<User?> logIn({required String email, required String password}) =>
      _repo.logIn(email: email, password: password).then((u) {
        currentUser = u;
        return u;
      });

  @override
  Future<void> logOut() => _repo.logOut().then((_) => currentUser = null);

  @override
  Future<String> createUser({
    required String name,
    required String userName,
    required String email,
    required String password,
  }) =>
      _repo.createUser(
        name: name,
        userName: userName,
        email: email,
        password: password,
      );

  @override
  Future<User?> getCurrentUserModel() => Future.value(_user);

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) =>
      _repo.changePassword(currentPassword, newPassword, confirmPassword);

  @override
  Future<String?> getToken() => _repo.getToken();

  @override
  Future<void> sendEmailVerification() {
    return _repo.sendEmailVerification();
  }

  @override
  Future<void> resendVerificationEmail({required String email}) =>
      _repo.resendVerificationEmail(email: email);

  @override
  Future<VerificationResult> verifyEmailToken({required String token}) =>
      _repo.verifyEmailToken(token: token);

  // Optional UI sugar:
  bool get isAuthenticated => _user != null;
}
