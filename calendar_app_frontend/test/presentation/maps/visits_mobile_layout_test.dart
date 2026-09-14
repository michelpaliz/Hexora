import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hexora/models/user_model/user.dart';
import 'package:hexora/models/group_model/group/group.dart';
import 'package:hexora/models/group_model/worker/worker.dart';
import 'package:hexora/models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/time_tracking/api/i_time_tracking_api_client.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/presentation/utils/location/geofenced_visit_tracking_service.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/geofenced_visits_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _User extends ChangeNotifier implements UserDomain {
  @override
  User get user => User(
      id: 'user-1',
      name: 'Michael',
      email: 'test@example.com',
      userName: 'michael',
      groupIds: [],
      emailVerified: true);
  @override
  Future<String> getAuthToken({bool forceRefresh = false}) async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api implements ITimeTrackingApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getWorkerVisits) {
      return Future.value(<WorkerVisit>[]);
    }
    return super.noSuchMethod(invocation);
  }
}

class _Repository implements ITimeTrackingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getWorkers) {
      return Future.value(const <Worker>[
        Worker(
            id: 'worker-1',
            groupId: 'group-1',
            userId: 'user-1',
            displayName: 'Michael',
            status: WorkerStatus.active),
      ]);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('mobile visits scroll without overflow at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final user = _User();
      final api = _Api();
      final tracking =
          GeofencedVisitTrackingService(api: api, userDomain: user);
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<UserDomain>.value(value: user),
            Provider<ITimeTrackingApiClient>.value(value: api),
            Provider<ITimeTrackingRepository>.value(value: _Repository()),
            ChangeNotifierProvider<GeofencedVisitTrackingService>.value(
                value: tracking),
          ],
          child: MaterialApp(
            theme: AppTheme.forPlatform(Brightness.light,
                platform: TargetPlatform.android),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GeofencedVisitsView(
                      group: Group(
                          id: 'group-1',
                          name: 'Test',
                          ownerId: 'user-1',
                          userRoles: const {},
                          userIds: const ['user-1'],
                          createdTime: DateTime(2026),
                          description: ''),
                      todayOnly: true,
                    ))),
          )));
      await tester.pumpAndSettle();
      expect(find.text('Seguimiento de visitas'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
          tester
              .getSize(find
                  .ancestor(
                      of: find.text('Añadir acompañantes'),
                      matching: find
                          .byWidgetPredicate((widget) => widget is TextButton))
                  .first)
              .width,
          greaterThan(200));
      await tester.ensureVisible(find.text('Iniciar'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar').hitTestable(), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView).first, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(find.text('Actualizar').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tracking.dispose();
      user.dispose();
    });
  }
}
