import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/sections/notifications_tab_view.dart';
import 'package:hexora/presentation/viewmodels/notifications/notification_view_model.dart';

class _ViewModel extends Fake implements NotificationViewModel {}

Widget app(
        Stream<List<NotificationUser>> stream, Future<void> Function() refresh,
        {List<NotificationUser>? initial}) =>
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: NotificationsTabView(
        notificationsStream: stream,
        initialNotifications: initial,
        notificationViewModel: _ViewModel(),
        activeJobs: const [],
        jobNotifications: const [],
        loadingJobNotifications: false,
        isAttentionJobNotification: (_) => false,
        onConfirm: (_) {},
        onOpenDocument: (_) {},
        onOpenActiveJob: (_) {},
        onOpenJobNotification: (_) {},
        onRefresh: refresh,
      )),
    );
void main() {
  testWidgets(
      'waits for first data, then empty screen supports refresh button and pull',
      (tester) async {
    final controller = StreamController<List<NotificationUser>>();
    addTearDown(controller.close);
    var refreshes = 0;
    await tester.pumpWidget(app(controller.stream, () async {
      refreshes++;
    }));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Actualizar'), findsNothing);
    controller.add([]);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(refreshes, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'cached empty data is shown without waiting for another stream event',
      (tester) async {
    final controller = StreamController<List<NotificationUser>>();
    addTearDown(controller.close);
    await tester.pumpWidget(app(controller.stream, () async {}, initial: []));
    await tester.pumpAndSettle();
    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
