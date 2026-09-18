import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/auth/auth_gate.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:provider/provider.dart';

class _StartupAuthService extends ChangeNotifier implements AuthService {
  Completer<void> startup = Completer<void>();
  int attempts = 0;

  @override
  Future<void> initialize() {
    attempts++;
    return startup.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('startup failure offers a retry and returns to loading',
      (tester) async {
    final auth = _StartupAuthService();
    addTearDown(auth.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: const MaterialApp(home: AuthGate()),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(auth.attempts, 1);

    auth.startup.completeError(StateError('Connection unavailable'));
    await tester.pump();
    expect(find.textContaining('Connection unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);

    auth.startup = Completer<void>();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(auth.attempts, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
