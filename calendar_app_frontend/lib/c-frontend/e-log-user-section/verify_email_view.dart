import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/c-frontend/j-routes/appRoutes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({Key? key}) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  void initState() {
    super.initState();
    _sendEmailVerification();
  }

  Future<void> _sendEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider
          .sendEmailVerification(); // Placeholder for future implementation
    } catch (error) {
      print('Error sending email verification: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "We've sent you an email verification. Please check your inbox and verify your account.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.loginRoute,
                  (route) => false,
                );
              },
              child: const Text('Restart'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailSentView extends StatelessWidget {
  const EmailSentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Sent')),
      body: const Center(
        child: Text(
          'Verification email sent successfully!',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
