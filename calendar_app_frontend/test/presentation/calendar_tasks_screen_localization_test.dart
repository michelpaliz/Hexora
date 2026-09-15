import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/event/model/event.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/data/group_management/event/repository/i_event_repository.dart';
import 'package:hexora/data/notification/domain/notification_domain.dart';
import 'package:hexora/data/user/domain/user_domain.dart';
import 'package:hexora/data/user/repository/i_user_repository.dart';
import 'package:hexora/presentation/features/calendar/screens/calendar/screen/widgets/calendar_tasks_screen.dart';
import 'package:hexora/theme/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  final task = Event(
    id: 'task-1',
    groupId: 'group-1',
    ownerId: 'owner-1',
    title: 'Prepare report',
    startDate: DateTime(2024, 7, 9, 14, 5),
    endDate: DateTime(2024, 7, 9, 14, 5),
  );

  testWidgets('shows English task labels and due date', (tester) async {
    await _pumpScreen(tester, const Locale('en'), task);

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Quick reminders without the work-visit form.'),
        findsOneWidget);
    expect(find.text('Tue, 9 Jul · 14:05'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(2));
  });

  testWidgets('shows Spanish task labels and due date', (tester) async {
    await _pumpScreen(tester, const Locale('es'), task);

    expect(find.text('Tareas'), findsOneWidget);
    expect(
      find.text('Recordatorios rápidos sin pasar por el flujo de visitas.'),
      findsOneWidget,
    );
    expect(find.text('mar, 9 jul · 14:05'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Locale locale,
  Event task,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<IEventRepository>.value(
          value: _FakeEventRepository([task]),
        ),
        ChangeNotifierProvider<UserDomain>.value(
          value: UserDomain(
            userRepository: _FakeUserRepository(),
            notificationDomain: NotificationDomain(),
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          extensions: [AppTypography.light()],
        ),
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: CalendarTasksScreen(group: _group),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _group = Group(
  id: 'group-1',
  name: 'Test group',
  ownerId: 'owner-1',
  userRoles: const {'owner-1': 'owner'},
  userIds: const ['owner-1'],
  createdTime: DateTime(2024),
  description: '',
);

class _FakeEventRepository implements IEventRepository {
  _FakeEventRepository(this.tasks);

  final List<Event> tasks;

  @override
  Future<List<Event>> getTasks({
    required String groupId,
    String? status,
    bool mine = false,
    DateTime? from,
    DateTime? to,
  }) async =>
      tasks;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserRepository implements IUserRepository {
  @override
  Future<List<User>> getUsersForGroup(Group group) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
