import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/auth/shared_utilities/auth_switcher_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Just delegate to AuthSwitcherView
    return const AuthSwitcherView();
  }
}
