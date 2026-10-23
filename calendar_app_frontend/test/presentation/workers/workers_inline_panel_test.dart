import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/time_tracking/time_entry.dart';
import 'package:hexora/models/time_tracking/working_time_history.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/right_panel_workers_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/worker_monthly_overview_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/month_list.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/monthly_overview/widgets/year_switcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/worker_time_tracking_screen.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/status_filter_chips.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/worker_directory_view.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/workers_form_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_list_section.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _User extends ChangeNotifier implements UserDomain {
  @override
  User? get user => User(
        id: 'owner',
        name: 'Owner',
        email: 'owner@example.com',
        userName: 'owner',
        groupIds: const ['group'],
        emailVerified: true,
      );

  @override
  Future<String> getAuthToken({bool forceRefresh = false}) async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements ITimeTrackingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getWorkers) {
      final status = invocation.namedArguments[#status] as WorkerStatus?;
      return Future.value([
        const Worker(
            id: 'worker',
            groupId: 'group',
            displayName: 'Trejo',
            status: WorkerStatus.active),
        const Worker(
            id: 'owner-worker',
            groupId: 'group',
            userId: 'owner',
            displayName: 'Zoe',
            status: WorkerStatus.active),
        const Worker(
            id: 'admin-worker',
            groupId: 'group',
            userId: 'admin',
            displayName: 'Michael',
            status: WorkerStatus.active),
        const Worker(
            id: 'co-admin-worker',
            groupId: 'group',
            userId: 'co-admin',
            displayName: 'Alex',
            status: WorkerStatus.archived),
      ].where((worker) => status == null || worker.status == status).toList());
    }
    if (invocation.memberName == #getActiveWorkersTotals ||
        invocation.memberName == #getWorkerTotals) {
      return Future.value(<String, dynamic>{});
    }
    if (invocation.memberName == #getWorkingTimeHistory) {
      return Future.value(WorkingTimeHistoryResponse.fromJson({}));
    }
    if (invocation.memberName == #getTimeEntries) {
      return Future.value(<TimeEntry>[]);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  testWidgets(
      'dashboard directory separates partners and preserves status filter',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<UserDomain>(create: (_) => _User()),
        Provider<ITimeTrackingRepository>(create: (_) => _Repository()),
      ],
      child: MaterialApp(
        theme: AppTheme.fromBrightness(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: WorkersInlinePanel(
                group: Group(
          id: 'group',
          name: 'Team',
          ownerId: 'owner',
          userRoles: {'admin': 'admin', 'co-admin': 'co-admin'},
          userIds: ['owner', 'admin', 'co-admin'],
          createdTime: DateTime(2026),
          description: '',
        ))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final directoryRect = tester.getRect(find.byType(WorkerDirectoryView));
    final formRect = tester.getRect(find.byType(WorkersFormPanel));
    expect(directoryRect.right, lessThan(formRect.left));
    expect(directoryRect.top, formRect.top);
    expect(directoryRect.width, greaterThan(formRect.width));
    List<String> visibleIds() => tester
        .widget<WorkerListSection>(find.byType(WorkerListSection))
        .workers
        .map((w) => w.id)
        .toList();
    expect(visibleIds(), ['worker']);
    await tester.tap(find.byTooltip('Resumen mensual').first);
    await tester.pumpAndSettle();
    expect(find.byType(WorkerMonthlyOverviewInline), findsOneWidget);
    expect(find.byType(WorkerDirectoryView), findsNothing);
    expect(
        Navigator.of(tester.element(find.byType(WorkersInlinePanel))).canPop(),
        isFalse);
    expect(find.text('Registrar horas'), findsWidgets);
    expect(
        tester
            .widget<WorkerMonthlyOverviewInline>(
                find.byType(WorkerMonthlyOverviewInline))
            .worker
            .id,
        'worker');
    expect(tester.takeException(), isNull);
    final monthsRect = tester.getRect(find.byType(MonthList));
    final valuesRect = tester.getRect(find.byType(WorkerTimeTrackingScreen));
    expect(monthsRect.right, lessThan(valuesRect.left));
    WorkerTimeTrackingScreen tracking() =>
        tester.widget<WorkerTimeTrackingScreen>(
            find.byType(WorkerTimeTrackingScreen));
    expect(tracking().embedded, isTrue);
    expect(tracking().worker.id, 'worker');
    final monthList = tester.widget<MonthList>(find.byType(MonthList));
    final nextMonth = monthList.selectedMonth == 1 ? 2 : 1;
    monthList.onTapMonth(nextMonth);
    await tester.pumpAndSettle();
    expect(tracking().initialMonth, nextMonth);
    final years = tester.widget<YearSwitcher>(find.byType(YearSwitcher));
    years.onYearChanged(years.year - 1);
    await tester.pumpAndSettle();
    expect(tracking().initialYear, years.year - 1);
    expect(tracking().initialMonth, nextMonth);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(visibleIds(), ['worker']);
    await tester.tap(find.byKey(const ValueKey('directory-partners')));
    await tester.pumpAndSettle();
    expect(visibleIds(), ['owner-worker', 'admin-worker', 'co-admin-worker']);
    expect(find.text('Propietario'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('Co-admin'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Michael');
    await tester.pumpAndSettle();
    expect(visibleIds(), ['admin-worker']);
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nombre (A–Z)').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nombre (Z–A)').last);
    await tester.pumpAndSettle();
    expect(visibleIds(), ['owner-worker', 'admin-worker', 'co-admin-worker']);
    await tester.tap(find.descendant(
      of: find.byType(StatusFilterChips),
      matching: find.text('Inactivo'),
    ));
    await tester.pumpAndSettle();
    expect(visibleIds(), ['co-admin-worker']);
    await tester.tap(find.byKey(const ValueKey('directory-workers')));
    await tester.pumpAndSettle();
    expect(find.text('No hay trabajadores con este estado.'), findsOneWidget);
    await tester.tap(find.text('Añadir trabajador'));
    await tester.pumpAndSettle();
    final form = tester.widget<WorkersFormPanel>(find.byType(WorkersFormPanel));
    expect(form.tabController.index, 1);
    expect(find.byType(WorkerDirectoryView), findsOneWidget);
    expect(find.text('Volver al equipo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
