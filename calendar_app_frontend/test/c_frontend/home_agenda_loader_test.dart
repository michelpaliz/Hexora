import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/resolver/event_group_resolver.dart';
import 'package:hexora/b-backend/group_mng_flow/recurrenceRule/recurrence_rule_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_agenda_domain.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/home_agenda_loader.dart';

Event event(String id, String type, int day) => Event(
      id: id,
      title: id,
      ownerId: 'user',
      groupId: 'group',
      type: type,
      startDate: DateTime(2026, 9, day, 10),
      endDate: DateTime(2026, 9, day, 11),
    );

class _Agenda extends UserAgendaDomain {
  DateTime? requestedFrom;
  @override
  Future<List<Event>> fetchAgendaRange(
      {required String groupId,
      required DateTime from,
      required DateTime to,
      String? tz,
      int? limit}) async {
    requestedFrom = from;
    return [event('work', 'work_visit', 12)];
  }
}

class _Events implements IEventRepository {
  @override
  Future<List<Event>> getEventsByGroupId(String groupId) async => [
        event('simple', 'simple', 11),
        event('old', 'simple', 1),
        event('later', 'simple', 30),
        event('work', 'work_visit', 12),
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('home agenda combines simple events and work in the selected range',
      () async {
    final agenda = _Agenda();
    final loader = HomeAgendaLoader(
        agenda: agenda,
        events: _Events(),
        resolver: GroupEventResolver(ruleService: RecurrenceRuleApiClient()));
    final result = await loader.load(
        groupId: 'group', days: 14, now: DateTime(2026, 9, 11, 15));
    expect(result.map((e) => e.id), ['simple', 'work']);
    expect(agenda.requestedFrom, DateTime(2026, 9, 11));
  });
}
