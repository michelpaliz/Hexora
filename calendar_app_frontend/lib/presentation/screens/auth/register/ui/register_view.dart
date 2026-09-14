import 'package:hexora/presentation/screens/auth/shared_utilities/auth_switcher_view.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Just delegate to AuthSwitcherView
    return const AuthSwitcherView();
  }
}
