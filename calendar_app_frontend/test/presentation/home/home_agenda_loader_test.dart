import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/services/user/domain/user_agenda_domain.dart';
import 'package:hexora/presentation/screens/agenda/home_agenda_loader.dart';

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
  List<String>? requestedTypes;
  @override
  Future<List<Event>> fetchWorkItems(
      {required String groupId,
      required DateTime from,
      required DateTime to,
      String? tz,
      List<String> types = const ['work_visit'],
      List<String>? clientIds,
      List<String>? serviceIds,
      int? skip,
      int? limit}) async {
    requestedFrom = from;
    requestedTypes = types;
    return [
      event('work', 'work_visit', 12),
      event('simple', 'simple', 11),
      event('service', 'work_service', 11)
    ];
  }
}

void main() {
  test('home agenda requests both work types and excludes simple events',
      () async {
    final agenda = _Agenda();
    final loader = HomeAgendaLoader(agenda: agenda);
    final result = await loader.load(
        groupId: 'group', days: 14, now: DateTime(2026, 9, 11, 15));
    expect(result.map((e) => e.id), ['service', 'work']);
    expect(agenda.requestedTypes, ['work_visit', 'work_service']);
    expect(agenda.requestedFrom, DateTime(2026, 9, 11));
  });
}
