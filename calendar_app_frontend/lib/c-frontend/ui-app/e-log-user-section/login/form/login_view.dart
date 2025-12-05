import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/shared_utilities/auth_switcher_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Just delegate to AuthSwitcherView
    return const AuthSwitcherView();
  }
}
