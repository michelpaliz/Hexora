import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/app/bootstrap/app_bootstrap.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/main.dart';

void main() {
  testWidgets('Hexora renders its bootstraped shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const HexoraApp(
        shell: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Bootstrapped Hexora'),
        ),
      ),
    );

    expect(find.byType(AppBootstrap), findsOneWidget);
    expect(find.text('Bootstrapped Hexora'), findsOneWidget);
  });

  testWidgets('startup failure renders the retry fallback',
      (WidgetTester tester) async {
    Widget? launchedApp;

    await startApp(
      initializeServices: () async => throw StateError('startup failed'),
      runApplication: (app) => launchedApp = app,
    );

    await tester.pumpWidget(launchedApp!);

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('session expiry clears tokens and redirects to login',
      (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var clearTokenCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Text('Protected content'),
        routes: {
          AppRoutes.loginRoute: (_) => const Text('Login screen'),
        },
      ),
    );

    await SessionExpiryHandler.handle(
      clearTokens: () async {
        clearTokenCalls++;
      },
      navigator: navigatorKey.currentState,
    );
    await tester.pumpAndSettle();

    expect(clearTokenCalls, 1);
    expect(find.text('Login screen'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
  });
}
