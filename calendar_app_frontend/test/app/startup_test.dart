import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/app/init_main.dart';
import 'package:hexora/main.dart';

void main() {
  test('initializes notifications before requesting permissions', () async {
    final calls = <String>[];

    await initializeAppServices(
      initializeLocalNotifications: () async => calls.add('initialize'),
      requestNotificationPermissions: () async => calls.add('permissions'),
    );

    expect(calls, ['initialize', 'permissions']);
  });

  testWidgets('starts the app after initializing services once', (_) async {
    var initializationCount = 0;
    Widget? launchedApp;
    final initializationComplete = Completer<void>();

    final startup = startApp(
      initializeServices: () {
        initializationCount++;
        return initializationComplete.future;
      },
      runApplication: (app) {
        launchedApp = app;
      },
    );

    expect(launchedApp, isNull);
    initializationComplete.complete();
    await startup;

    expect(initializationCount, 1);
    expect(launchedApp, isA<HexoraApp>());
  });

}
import 'dart:async';
