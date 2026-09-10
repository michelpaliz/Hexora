import 'package:shared_preferences/shared_preferences.dart';

/// Legacy verification state must never decide whether the login UI is shown.
class EmailVerificationState {
  static const pendingVerificationEmailKey = 'pendingVerificationEmail';
  static const requiresEmailVerificationKey = 'requiresEmailVerification';

  static Future<void> clearPersisted() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(pendingVerificationEmailKey),
      preferences.remove(requiresEmailVerificationKey),
    ]);
  }
}
