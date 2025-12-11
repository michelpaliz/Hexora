// c-frontend/d-log-user-section/shared_utilities/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:provider/provider.dart';

import 'package:hexora/c-frontend/ui-app/a-home-section/home_page/home_page.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/shared_utilities/auth_switcher_view.dart';

/// Shows a splash while AuthService.initialize() runs,
/// then listens to currentUser and switches between login/home.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = context.read<AuthService>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline),
                  const SizedBox(height: 8),
                  Text('Failed to start: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // retry: clear cached future and re-run
                        _initFuture = context.read<AuthService>().initialize();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = context.watch<AuthService>().currentUser;
        return user == null ? const AuthSwitcherView() : const HomePage();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}