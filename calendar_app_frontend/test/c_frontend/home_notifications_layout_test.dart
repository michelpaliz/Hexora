import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/jobs/job_notification.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/sections/notifications_tab_view.dart';
import 'package:hexora/c-frontend/viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _ViewModel implements NotificationViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('home notifications leave room for list at $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final jobs = List.generate(
          12,
          (i) => JobNotification.fromJson({
                'id': '$i',
                'type': 'OCR_IMPORT',
                'title': 'Import $i',
                'message': 'Documents processed',
                'severity': 'warning',
              }));
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
            body: NotificationsTabView(
          notificationsStream: Stream.value(<NotificationUser>[]),
          notificationViewModel: _ViewModel(),
          activeJobs: const [],
          jobNotifications: jobs,
          loadingJobNotifications: false,
          isAttentionJobNotification: (_) => true,
          onConfirm: (_) {},
          onOpenDocument: (_) {},
          onOpenActiveJob: (_) {},
          onOpenJobNotification: (_) {},
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Import 0'), findsNothing);
      expect(tester.getSize(find.byType(TabBarView)).height, greaterThan(400));
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      expect(find.text('Import 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
