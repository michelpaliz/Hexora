import 'package:hexora/models/group_model/event/model/event.dart';
import 'package:hexora/services/user/domain/user_agenda_domain.dart';

/// Loads scheduled work for the home Agenda.
class HomeAgendaLoader {
  const HomeAgendaLoader({
    required this.agenda,
  });

  final UserAgendaDomain agenda;

  Future<List<Event>> load({
    required String groupId,
    required int days,
    DateTime? now,
  }) async {
    final today = (now ?? DateTime.now()).toLocal();
    final from = DateTime(today.year, today.month, today.day);
    final to = DateTime(today.year, today.month, today.day + days);
    final events = await agenda.fetchWorkItems(
      groupId: groupId,
      from: from,
      to: to,
      types: const ['work_visit', 'work_service'],
      limit: 300,
    );
    final work = events
        .where((event) =>
            event.type.toLowerCase() == 'work_visit' ||
            event.type.toLowerCase() == 'work_service')
        .toList();
    work.sort((a, b) => a.startDate.compareTo(b.startDate));
    return work;
  }
}
