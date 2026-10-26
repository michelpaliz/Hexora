import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/navigation/shell/worker_status_indicator.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _UserDomain extends ChangeNotifier implements UserDomain {
  @override
  Future<String> getAuthToken({bool forceRefresh = false}) async => 'token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements ITimeTrackingRepository {
  _Repo(this.totals);

  final Map<String, dynamic> totals;
  final List<String> requestedGroupIds = [];

  @override
  Future<Map<String, dynamic>> getActiveWorkersTotals(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  }) async {
    requestedGroupIds.add(groupId);
    return totals;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required String groupId,
  required _Repo repo,
  required VoidCallback onOpenWorkers,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final userDomain = _UserDomain();
  addTearDown(userDomain.dispose);
  final presence = PresenceDomain();
  addTearDown(presence.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserDomain>.value(value: userDomain),
        Provider<ITimeTrackingRepository>.value(value: repo),
        ChangeNotifierProvider<PresenceDomain>.value(value: presence),
      ],
      child: MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: WorkerStatusIndicator(
              groupId: groupId,
              memberIds: const ['one', 'two'],
              groupRoles: const {},
              onOpenWorkers: onOpenWorkers,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'working-now count comes from active worker totals, not total workers',
      (tester) async {
    final repo = _Repo({
      'activeWorkersCount': 3,
      'totalWorkersCount': 99,
    });
    await _pumpIndicator(
      tester,
      groupId: 'group-a',
      repo: repo,
      onOpenWorkers: () {},
    );

    // The indicator surfaces `activeWorkersCount` (3), never the 99 total.
    expect(repo.requestedGroupIds, ['group-a']);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('99'), findsNothing);
    expect(find.text('trabajando'), findsOneWidget);
  });

  testWidgets(
      'view workers opens the onOpenWorkers handler and closes the menu',
      (tester) async {
    final repo = _Repo({'activeWorkersCount': 2});
    var opened = 0;
    await _pumpIndicator(
      tester,
      groupId: 'group-b',
      repo: repo,
      onOpenWorkers: () => opened++,
    );

    await tester.tap(find.byIcon(Icons.people_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Trabajando ahora'), findsOneWidget);
    expect(find.text('Ver trabajadores'), findsOneWidget);

    await tester.tap(find.text('Ver trabajadores'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(find.text('Ver trabajadores'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reloads the active count when the selected group changes',
      (tester) async {
    final repo = _Repo({'activeWorkersCount': 5});
    await _pumpIndicator(
      tester,
      groupId: 'group-1',
      repo: repo,
      onOpenWorkers: () {},
    );
    expect(repo.requestedGroupIds, ['group-1']);

    // Rebuild the same widget with a different group: it must refetch.
    final userDomain = _UserDomain();
    addTearDown(userDomain.dispose);
    final presence = PresenceDomain();
    addTearDown(presence.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserDomain>.value(value: userDomain),
          Provider<ITimeTrackingRepository>.value(value: repo),
          ChangeNotifierProvider<PresenceDomain>.value(value: presence),
        ],
        child: MaterialApp(
          theme: AppTheme.forPlatform(
            Brightness.light,
            platform: TargetPlatform.windows,
          ),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: WorkerStatusIndicator(
                groupId: 'group-2',
                memberIds: const ['one', 'two'],
                groupRoles: const {},
                onOpenWorkers: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.requestedGroupIds, ['group-1', 'group-2']);
  });
}
