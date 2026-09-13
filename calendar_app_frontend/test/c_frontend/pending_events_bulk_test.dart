import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events_section.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

Event event(String id, {String owner = 'me'}) => Event(
    id: id,
    ownerId: owner,
    title: 'Pending $id',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 1, 1));

class Repo implements IEventRepository {
  Repo(this.events);
  List<Event> events;
  final calls = <String>[];
  final failures = <String>{};
  Completer<void>? gate;
  @override
  Future<List<Event>> getEventsByGroupId(String id) async => List.of(events);
  @override
  Future<Event> markEventAsDone(String id, {required bool isDone}) async {
    calls.add(id);
    await gate?.future;
    if (failures.contains(id)) throw Exception('Failed $id');
    final index = events.indexWhere((e) => e.id == id);
    return events[index] = events[index].copyWith(isDone: isDone);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Users extends ChangeNotifier implements UserDomain {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GroupUndoneEventsViewModel model(Repo repo) => GroupUndoneEventsViewModel(
    groupId: 'group',
    currentUserId: 'me',
    role: GroupRole.admin,
    eventRepository: repo,
    userResolver: (_) async => null);

void main() {
  test(
      'bulk respects permissions, deduplicates, keeps failures pending and retries',
      () async {
    final repo = Repo([event('1'), event('2'), event('3', owner: 'other')]);
    repo.failures.add('2');
    final vm = model(repo);
    addTearDown(vm.dispose);
    await vm.refresh();
    final result = await vm.markAllAsDone(['1', '1', '2', '3']);
    expect(result, (completed: 1, failed: 1));
    expect(repo.calls, ['1', '2']);
    expect(vm.pendingEvents.map((e) => e.id), ['2', '3']);
    repo.failures.clear();
    expect(await vm.markAllAsDone(['1', '2', '3']), (completed: 1, failed: 0));
    expect(repo.calls, ['1', '2', '2']);
  });
  test('bulk snapshots filtered selection and blocks duplicate submissions',
      () async {
    final repo = Repo([event('1'), event('2', owner: 'other')]);
    final vm = model(repo);
    addTearDown(vm.dispose);
    await vm.refresh();
    vm.setFilterUser('other');
    expect(await vm.markAllAsDone(['1', '2']), (completed: 0, failed: 0));
    vm.setFilterUser(null);
    repo.gate = Completer<void>();
    final operation = vm.markAllAsDone(['1']);
    expect(vm.isCompletingAll, isTrue);
    await vm.markAllAsDone(['1']);
    await vm.markEventAsDone('1');
    expect(repo.calls, ['1']);
    repo.gate!.complete();
    await operation;
    expect(vm.isCompletingAll, isFalse);
    expect(vm.bulkFinished, 1);
  });
  testWidgets(
      'compact dashboard total opens full list, confirms bulk, and refreshes on return',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = Repo([for (var i = 0; i < 8; i++) event('$i')]);
    final group = Group(
        id: 'group',
        name: 'Team',
        ownerId: 'me',
        userRoles: {},
        userIds: ['me'],
        createdTime: DateTime(2026),
        description: '');
    final user = User(
        id: 'me',
        name: 'Me',
        email: '',
        userName: 'me',
        groupIds: ['group'],
        emailVerified: true);
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<IEventRepository>.value(value: repo),
          ChangeNotifierProvider<UserDomain>(create: (_) => Users()),
        ],
        child: MaterialApp(
          theme: AppTheme.forPlatform(Brightness.light,
              platform: TargetPlatform.android),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: GroupUndoneEventsSection(
                  group: group, user: user, role: GroupRole.member)),
        )));
    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Pending 0'), findsNothing);
    expect(tester.getSize(find.byType(Card)).height, lessThan(110));
    await tester.tap(find.text('Eventos pendientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar todos como hechos (8)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    await tester.tap(find.text('Marcar todos como hechos (8)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completar todos'));
    await tester.pumpAndSettle();
    expect(repo.calls.length, 8);
    expect(repo.events.every((e) => e.isDone == true), isTrue);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
