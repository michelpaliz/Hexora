import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/resolver/event_group_resolver.dart';
import 'package:hexora/b-backend/user/domain/user_agenda_domain.dart';

/// Combines scheduled work with the calendar's simple event occurrences.
class HomeAgendaLoader {
  const HomeAgendaLoader({
    required this.agenda,
    required this.events,
    required this.resolver,
  });

  final UserAgendaDomain agenda;
  final IEventRepository events;
  final GroupEventResolver resolver;

  Future<List<Event>> load({
    required String groupId,
    required int days,
    DateTime? now,
  }) async {
    final today = (now ?? DateTime.now()).toLocal();
    final from = DateTime(today.year, today.month, today.day);
    final to = DateTime(today.year, today.month, today.day + days);
    final results = await Future.wait([
      agenda.fetchAgendaRange(groupId: groupId, from: from, to: to, limit: 300),
      events.getEventsByGroupId(groupId),
    ]);
    final simple = results[1]
        .where((event) => event.type.toLowerCase() == 'simple')
        .toList();
    final hydrated = await resolver.hydrateRulesForEvents(simple);
    final occurrences = resolver.expandForRange(
      baseEvents: hydrated,
      range: DateTimeRange(start: from, end: to),
    );
    final combined = <String, Event>{
      for (final event in [...results[0], ...occurrences])
        '${event.id}:${event.startDate.toUtc().toIso8601String()}': event,
    }.values.toList();
    combined.sort((a, b) => a.startDate.compareTo(b.startDate));
    return combined;
  }
}
