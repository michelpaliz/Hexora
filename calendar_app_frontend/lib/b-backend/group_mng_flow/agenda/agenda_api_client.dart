// agenda_services.dart
import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/agenda/query_knobs/client_rollup.dart';
import 'package:hexora/b-backend/group_mng_flow/agenda/query_knobs/work_summary.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

/// Unified AgendaService — talks to:
///   GET /api/agenda/work?groupId=...&from=ISO&to=ISO
///     [&types=work_visit,...]
///     [&clientIds=...,&serviceIds=...]
///     [&aggregate=none|summary|by_client|by_service]
///     [&minutesSource=auto|planned|actual]
class AgendaApiClient {
  final String _baseUrl = '${ApiConstants.baseUrl}/agenda';
  final http.Client _client;

  AgendaApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenService.loadToken();
    if (token == null) throw Exception("Authentication token not found");
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Uri _u(String path, Map<String, Object?> qp) {
    final q = <String, String>{};
    qp.forEach((k, v) {
      if (v == null) return;
      if (v is Iterable) {
        final s =
            v.where((e) => e != null && e.toString().isNotEmpty).join(',');
        if (s.isNotEmpty) q[k] = s;
      } else {
        final s = v.toString();
        if (s.isNotEmpty) q[k] = s;
      }
    });
    return Uri.parse('$_baseUrl$path')
        .replace(queryParameters: q.isEmpty ? null : q);
  }

  T _decode<T>(http.Response r, T Function(dynamic) map) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    devtools.log('📥 [AgendaService] ${r.request?.url} → ${r.statusCode}');
    if (!ok) {
      final msg = (body is Map && body['error'] is String)
          ? body['error']
          : r.reasonPhrase ?? 'Request failed';
      throw Exception(msg);
    }
    return map(body);
  }

  // -------------------------------
  // RAW ITEMS (aggregate=none)
  // -------------------------------
  Future<List<Event>> fetchWorkItems({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'], // your backend default
    List<String>? clientIds,
    List<String>? serviceIds,
    int? limit,
    int? skip,
    String minutesSource = 'auto', // not used for items, but harmless to pass
    String? tz,
  }) async {
    if (!from.isBefore(to)) {
      throw ArgumentError('`from` must be strictly before `to`');
    }

    final uri = _u('/work', {
      'groupId': groupId,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      if (types.isNotEmpty) 'types': types,
      if (clientIds != null && clientIds.isNotEmpty) 'clientIds': clientIds,
      if (serviceIds != null && serviceIds.isNotEmpty) 'serviceIds': serviceIds,
      if (limit != null) 'limit': limit,
      if (skip != null) 'skip': skip,
      if (tz != null && tz.isNotEmpty) 'tz': tz,
      'aggregate': 'none',
      'minutesSource': minutesSource,
    });

    final res = await _client.get(uri, headers: await _authHeaders());
    return _decode<List<Event>>(res, (j) {
      final items =
          (j is Map && j['items'] is List) ? j['items'] as List : const [];
      final events = items
          .map<Event>((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      return events;
    });
  }

  // -------------------------------
  // SUMMARY (aggregate=summary)
  // -------------------------------
  Future<WorkSummary> fetchWorkSummary({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
    String minutesSource = 'auto', // auto | planned | actual
    String? tz,
  }) async {
    final uri = _u('/work', {
      'groupId': groupId,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      if (types.isNotEmpty) 'types': types,
      if (clientIds != null && clientIds.isNotEmpty) 'clientIds': clientIds,
      if (serviceIds != null && serviceIds.isNotEmpty) 'serviceIds': serviceIds,
      'aggregate': 'summary',
      'minutesSource': minutesSource,
      if (tz != null && tz.isNotEmpty) 'tz': tz,
    });

    final res = await _client.get(uri, headers: await _authHeaders());
    return _decode<WorkSummary>(
        res, (j) => WorkSummary.fromJson(j as Map<String, dynamic>));
  }

  // -------------------------------
  // BY CLIENT (aggregate=by_client)
  // -------------------------------
  Future<List<ClientRollup>> fetchWorkByClient({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds, // can pre-filter
    List<String>? serviceIds,
    int? limit,
    int? skip,
    String minutesSource = 'auto',
    String? tz,
  }) async {
    final uri = _u('/work', {
      'groupId': groupId,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      if (types.isNotEmpty) 'types': types,
      if (clientIds != null && clientIds.isNotEmpty) 'clientIds': clientIds,
      if (serviceIds != null && serviceIds.isNotEmpty) 'serviceIds': serviceIds,
      if (limit != null) 'limit': limit,
      if (skip != null) 'skip': skip,
      'aggregate': 'by_client',
      'minutesSource': minutesSource,
      if (tz != null && tz.isNotEmpty) 'tz': tz,
    });

    final res = await _client.get(uri, headers: await _authHeaders());
    return _decode<List<ClientRollup>>(res, (j) {
      final items =
          (j is Map && j['items'] is List) ? j['items'] as List : const [];
      return items
          .map((e) => ClientRollup.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  // -------------------------------
  // BY SERVICE (aggregate=by_service)
  // -------------------------------
  Future<List<ServiceRollup>> fetchWorkByService({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds, // can pre-filter or leave null to get all
    int? limit,
    int? skip,
    String minutesSource = 'auto',
    String? tz,
  }) async {
    final uri = _u('/work', {
      'groupId': groupId,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      if (types.isNotEmpty) 'types': types,
      if (clientIds != null && clientIds.isNotEmpty) 'clientIds': clientIds,
      if (serviceIds != null && serviceIds.isNotEmpty) 'serviceIds': serviceIds,
      if (limit != null) 'limit': limit,
      if (skip != null) 'skip': skip,
      'aggregate': 'by_service',
      'minutesSource': minutesSource,
      if (tz != null && tz.isNotEmpty) 'tz': tz,
    });

    final res = await _client.get(uri, headers: await _authHeaders());
    return _decode<List<ServiceRollup>>(res, (j) {
      final items =
          (j is Map && j['items'] is List) ? j['items'] as List : const [];
      return items
          .map((e) => ServiceRollup.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  // -------------------------------
  // Convenience helpers
  // -------------------------------

  /// Past hours between [from, to] (summary). Uses `minutesSource=auto`:
  /// prefers `actualMinutes` for past, falls back to duration.
  Future<WorkSummary> pastHours({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
  }) {
    return fetchWorkSummary(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
      minutesSource: 'auto',
    );
  }

  /// Forecast future hours between [from, to] (summary).
  /// Uses `minutesSource=planned` by default.
  Future<WorkSummary> futureForecast({
    required String groupId,
    required DateTime from,
    required DateTime to,
    List<String> types = const ['work_visit'],
    List<String>? clientIds,
    List<String>? serviceIds,
  }) {
    return fetchWorkSummary(
      groupId: groupId,
      from: from,
      to: to,
      types: types,
      clientIds: clientIds,
      serviceIds: serviceIds,
      minutesSource: 'planned',
    );
  }

  // -------------------------------
  // Legacy wrappers (optional)
  // -------------------------------

  /// Kept for compatibility; calls /work with aggregate=none.
  Future<List<Event>> fetchRange({
    required DateTime from,
    required DateTime to,
    required String groupId,
    String? tz,
    int? limit,
  }) {
    return fetchWorkItems(
      groupId: groupId,
      from: from,
      to: to,
      tz: tz,
      limit: limit,
    );
  }

  /// If you still need “upcoming X days” as items.
  Future<List<Event>> fetchUpcoming({
    required String groupId,
    int days = 14,
    int limit = 200,
    String? tz,
  }) {
    final now = DateTime.now().toUtc();
    final end = now.add(Duration(days: days));
    return fetchWorkItems(
      groupId: groupId,
      from: now,
      to: end,
      tz: tz,
      limit: limit,
    );
  }

  // -------------------------------

  void dispose() {
    _client.close();
  }
}
