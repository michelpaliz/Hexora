import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    final user = authProvider.currentUser;
    if (user != null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.homePage);
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
