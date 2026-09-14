import 'package:flutter/material.dart';

class RegisterController {
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final name = TextEditingController();
  final userName = TextEditingController();

  void dispose() {
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    name.dispose();
    userName.dispose();
  }
}
