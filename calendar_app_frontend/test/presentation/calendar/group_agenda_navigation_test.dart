import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/user/domain/user_agenda_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/presentation/routes/routes.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_actions.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/navigation/dashboard_sections.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_state.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _User extends ChangeNotifier implements UserDomain {
  @override
  final currentUserNotifier = ValueNotifier<User?>(null);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void dispose() {
    currentUserNotifier.dispose();
    super.dispose();
  }
}

class _Agenda implements UserAgendaDomain {
  final calls = <({String group, int days})>[];
  @override
  Future<List<Event>> fetchWorkItems(
      {required String groupId,
      required DateTime from,
      required DateTime to,
      List<String> types = const ['work_visit'],
      List<String>? clientIds,
      List<String>? serviceIds,
      int? limit,
      int? skip,
      String? tz}) async {
    calls.add((group: groupId, days: to.difference(from).inDays));
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Dashboard implements GroupDashboardState {
  _Dashboard(this.context, this.group);
  @override
  final BuildContext context;
  @override
  final Group group;
  @override
  bool get isWide => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'dashboard agenda loads its group and returns without main navigation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final agenda = _Agenda();
    Group? eventGroup;
    final group = Group(
        id: 'selected-group',
        name: 'Garden team',
        ownerId: 'owner',
        userRoles: {},
        userIds: [],
        createdTime: DateTime(2026),
        description: '');
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<UserDomain>(create: (_) => _User()),
        Provider<UserAgendaDomain>.value(value: agenda),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          AppRoutes.agenda: routes[AppRoutes.agenda]!,
          AppRoutes.addEvent: (context) {
            eventGroup = ModalRoute.of(context)!.settings.arguments as Group;
            return Scaffold(
                appBar: AppBar(), body: const Text('Add group event'));
          },
        },
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => DashboardActions.openSection(
                      _Dashboard(context, group), Sections.agenda),
                  child: const Text('Open group agenda'),
                ))),
      ),
    ));
    await tester.tap(find.text('Open group agenda'));
    await tester.pumpAndSettle();
    expect(agenda.calls, [(group: 'selected-group', days: 14)]);
    expect(find.text('Agenda · Garden team'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Elegir'), findsNothing);
    await tester.tap(find.text('30d'));
    await tester.pumpAndSettle();
    expect(agenda.calls.last, (group: 'selected-group', days: 30));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(eventGroup, same(group));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open group agenda'), findsOneWidget);
  });
}
