import 'package:hexora/c-frontend/ui-app/e-log-user-section/shared_utilities/auth_switcher_view.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({
    super.key,
    this.termsUrl,
    this.privacyUrl,
  });

  /// Public URL for the Terms of Service shown during registration.
  final String? termsUrl;

  /// Public URL for the Privacy Policy shown during registration.
  final String? privacyUrl;

  @override
  Widget build(BuildContext context) {
    // Just delegate to AuthSwitcherView
    return AuthSwitcherView(
      termsUrl: termsUrl,
      privacyUrl: privacyUrl,
    );
  }
}
