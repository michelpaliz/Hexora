import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/agenda/agenda_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/agenda/query_knobs/client_rollup.dart';
import 'package:hexora/b-backend/group_mng_flow/agenda/query_knobs/work_summary.dart';

class UserAgendaDomain {
  final AgendaApiClient _agendaService;

  UserAgendaDomain({AgendaApiClient? agendaService})
      : _agendaService = agendaService ?? AgendaApiClient();

  Future<List<Event>> fetchAgendaUpcoming({
    required String groupId,
    int days = 14,
    int limit = 200,
    String? tz,
  }) {
    return _agendaService.fetchUpcoming(
      groupId: groupId,
      days: days,
      limit: limit,
      tz: tz,
    );
  }

  Future<List<Event>> fetchAgendaRange({
    required String groupId,
    required DateTime from,
    required DateTime to,
    String? tz,
    int? limit,
  }) {
    return _agendaService.fetchRange(
      groupId: groupId,
      from: from,
      to: to,
      tz: tz,
      limit: limit,
    );
  }

  Future<List<Event>> fetchAgendaTodayAndTomorrow({
    required String groupId,
    String? tz,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 2));
    return _agendaService.fetchWorkItems(
      groupId: groupId,
      from: start,
      to: end,
      tz: tz,
    );
  }

  Future<List<Event>> fetchWorkItems({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
    int? limit,
    int? skip,
    String? tz,
  }) {
    return _agendaService.fetchWorkItems(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
      limit: limit,
      skip: skip,
      tz: tz,
    );
  }

  Future<WorkSummary> fetchWorkSummary({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
    String minutesSource = 'auto',
    String? tz,
  }) {
    return _agendaService.fetchWorkSummary(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
      minutesSource: minutesSource,
      tz: tz,
    );
  }

  Future<List<ClientRollup>> fetchWorkByClient({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
    int? limit,
    int? skip,
    String minutesSource = 'auto',
    String? tz,
  }) {
    return _agendaService.fetchWorkByClient(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
      limit: limit,
      skip: skip,
      minutesSource: minutesSource,
      tz: tz,
    );
  }

  Future<List<ServiceRollup>> fetchWorkByService({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
    int? limit,
    int? skip,
    String minutesSource = 'auto',
    String? tz,
  }) {
    return _agendaService.fetchWorkByService(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
      limit: limit,
      skip: skip,
      minutesSource: minutesSource,
      tz: tz,
    );
  }

  Future<WorkSummary> pastHours({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
  }) {
    return _agendaService.pastHours(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
    );
  }

  Future<WorkSummary> futureForecast({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
  }) {
    return _agendaService.futureForecast(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
    );
  }
}
