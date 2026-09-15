import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/event/model/event.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/data/group_management/event/domain/event_domain.dart';
import 'package:hexora/data/group_management/event/repository/i_event_repository.dart';
import 'package:hexora/data/group_management/event/resolver/event_group_resolver.dart';
import 'package:hexora/data/group_management/group/domain/group_domain.dart';
import 'package:hexora/data/group_management/group/repository/i_group_repository.dart';
import 'package:hexora/data/group_management/recurrence_rule/recurrence_rule_api_client.dart';
import 'package:hexora/data/user/repository/i_user_repository.dart';

void main() {
  testWidgets('retains bootstrap reminder reconciliation', (tester) async {
    final event = _event();
    final synced = <Event>[];
    final domain = await _buildDomain(
      tester,
      _FakeEventRepository(events: [event]),
      synced,
      <Event>[],
    );

    expect(synced, [event]);
    domain.dispose();
  });

  testWidgets('schedules a reminder immediately after a successful create',
      (tester) async {
    final repository = _FakeEventRepository();
    final synced = <Event>[];
    final domain = await _buildDomain(tester, repository, synced, <Event>[]);
    final event = _event();

    final result = await domain.createEvent(
      tester.element(find.byKey(_testContextKey)),
      event,
    );

    expect(synced, [event]);
    expect(result.event, event);
    expect(result.reminderUnavailable, isFalse);
    expect(repository.refreshCalls, 1);
    domain.dispose();
  });

  testWidgets('reschedules a reminder immediately after a successful update',
      (tester) async {
    final event = _event();
    final repository = _FakeEventRepository(events: [event]);
    final synced = <Event>[];
    final domain = await _buildDomain(tester, repository, synced, <Event>[]);
    synced.clear();
    final updated = event.copyWith(
      startDate: event.startDate.add(const Duration(hours: 1)),
      endDate: event.endDate.add(const Duration(hours: 1)),
      reminderTime: 30,
    );

    final result = await domain.updateEvent(
      tester.element(find.byKey(_testContextKey)),
      updated,
    );

    expect(synced, [updated]);
    expect(result.event, updated);
    expect(result.reminderUnavailable, isFalse);
    expect(repository.refreshCalls, 1);
    domain.dispose();
  });

  testWidgets('cancels a reminder immediately after a successful delete',
      (tester) async {
    final event = _event(id: 'event-1');
    final repository = _FakeEventRepository(events: [event]);
    final cancelled = <Event>[];
    final domain = await _buildDomain(tester, repository, <Event>[], cancelled);

    await domain.deleteEvent(event.id);

    expect(cancelled, [event]);
    expect(repository.refreshCalls, 1);
    domain.dispose();
  });

  testWidgets('creates the event when reminder scheduling fails',
      (tester) async {
    final repository = _FakeEventRepository();
    final domain = await _buildDomain(
      tester,
      repository,
      <Event>[],
      <Event>[],
      reminderSynchronizer: (
        _,
        __, {
        bool showSchedulingStatus = false,
      }) async {
        throw StateError('notification permission unavailable');
      },
    );
    final event = _event();

    final result = await domain.createEvent(
      tester.element(find.byKey(_testContextKey)),
      event,
    );

    expect(result.event, event);
    expect(result.reminderUnavailable, isTrue);
    expect(await repository.getEventsByGroupId(_group.id), [event]);
    domain.dispose();
  });

  testWidgets('updates the event when reminder scheduling fails',
      (tester) async {
    final event = _event();
    final repository = _FakeEventRepository(events: [event]);
    final domain = await _buildDomain(
      tester,
      repository,
      <Event>[],
      <Event>[],
      reminderSynchronizer: (
        _,
        __, {
        bool showSchedulingStatus = false,
      }) async {
        throw StateError('notification permission unavailable');
      },
    );
    final updated = event.copyWith(reminderTime: 30);

    final result = await domain.updateEvent(
      tester.element(find.byKey(_testContextKey)),
      updated,
    );

    expect(result.event, updated);
    expect(result.reminderUnavailable, isTrue);
    expect(await repository.getEventsByGroupId(_group.id), [updated]);
    domain.dispose();
  });
}

Future<EventDomain> _buildDomain(
  WidgetTester tester,
  _FakeEventRepository repository,
  List<Event> synced,
  List<Event> cancelled, {
  ReminderSynchronizer? reminderSynchronizer,
}) async {
  await tester.pumpWidget(
    const MaterialApp(home: SizedBox(key: _testContextKey)),
  );
  final domain = EventDomain(
    const [],
    context: tester.element(find.byKey(_testContextKey)),
    group: _group,
    repository: repository,
    groupDomain: GroupDomain(
      groupRepository: _FakeGroupRepository(),
      userRepository: _FakeUserRepository(),
      groupEventResolver: GroupEventResolver(
        ruleService: RecurrenceRuleApiClient(),
      ),
      user: null,
    ),
    resolver: GroupEventResolver(ruleService: RecurrenceRuleApiClient()),
    reminderSynchronizer: reminderSynchronizer ??
        (
          _,
          event, {
          bool showSchedulingStatus = false,
        }) async {
          synced.add(event);
        },
    reminderCanceller: (event) async {
      cancelled.add(event);
    },
  );
  await tester.pumpAndSettle();
  return domain;
}

const _testContextKey = Key('event-domain-reminder-sync');

final _group = Group(
  id: 'group-1',
  name: 'Test group',
  ownerId: 'owner-1',
  userRoles: const {'owner-1': 'owner'},
  userIds: const ['owner-1'],
  createdTime: DateTime(2024),
  description: '',
);

Event _event({String id = 'event-1'}) {
  final start = DateTime(2030, 1, 1, 10);
  return Event(
    id: id,
    groupId: _group.id,
    ownerId: _group.ownerId,
    title: 'Reminder event',
    startDate: start,
    endDate: start.add(const Duration(hours: 1)),
    reminderTime: 15,
  );
}

class _FakeEventRepository implements IEventRepository {
  _FakeEventRepository({List<Event>? events}) : _events = [...?events];

  final List<Event> _events;
  int refreshCalls = 0;

  @override
  Future<Event> createEvent(Event event) async {
    _events.add(event);
    return event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    _events.removeWhere((event) => event.id == id);
  }

  @override
  Stream<List<Event>> events$(String groupId) => const Stream.empty();

  @override
  Future<List<Event>> getEventsByGroupId(String groupId) async =>
      List<Event>.from(_events);

  @override
  Future<void> refreshGroup(String groupId) async {
    refreshCalls++;
  }

  @override
  Future<Event> updateEvent(Event event) async {
    final index = _events.indexWhere((existing) => existing.id == event.id);
    if (index == -1) {
      _events.add(event);
    } else {
      _events[index] = event;
    }
    return event;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGroupRepository implements IGroupRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserRepository implements IUserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
