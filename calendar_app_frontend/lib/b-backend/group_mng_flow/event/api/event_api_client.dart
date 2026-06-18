import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/group_mng_flow/event/api/i_event_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/string_utils.dart';
import 'package:hexora/b-backend/group_mng_flow/recurrenceRule/recurrence_rule_api_client.dart';
import 'package:http/http.dart' as http;

class EventApiClient implements IEventApiClient {
  EventApiClient({
    http.Client? client,
    RecurrenceRuleApiClient? ruleService,
  })  : _client = client ?? http.Client(),
        _ruleService = ruleService ?? RecurrenceRuleApiClient();

  final http.Client _client;
  final RecurrenceRuleApiClient _ruleService;

  final String baseUrl = '${ApiConstants.baseUrl}/events';
  final String tasksUrl = '${ApiConstants.baseUrl}/events/tasks';

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Future<Event> _ensureRuleId(Event ev, String token) async {
    if (ev.recurrenceRule == null) return ev;

    // Case-insensitive hex check for 24-char Mongo ObjectId
    final isObjectId = RegExp(r'^[a-f0-9]{24}$', caseSensitive: false)
        .hasMatch(ev.recurrenceRule!.id);
    if (isObjectId) return ev;

    final created = await _ruleService.createRule(ev.recurrenceRule!);
    return ev.copyWith(recurrenceRule: created);
  }

  @override
  Future<Event> createEvent(Event eventData, String token) async {
    try {
      final readyEvent = await _ensureRuleId(eventData, token);
      final headers = _authHeaders(token);
      final body = jsonEncode(readyEvent.toBackendJson());

      debugPrint('ðŸŒ POST /events body: $body');

      devtools.log("ðŸ“¤ Sending event to $baseUrl");
      devtools.log("ðŸ§¾ Headers: $headers");
      devtools.log("ðŸ“ Event body: $body");

      final res = await AuthenticatedHttpClient.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: body,
        client: _client,
      );

      if (res.statusCode == 201) {
        return Event.fromJson(jsonDecode(res.body));
      }

      devtools.log("❌ Failed response: ${res.statusCode}");
      devtools.log("❌ Response body: ${res.body}");
      throw Exception('Failed to create event: ${res.body}');
    } catch (error) {
      devtools.log('[EXCEPTION] Create error: $error');
      rethrow;
    }
  }

  @override
  Future<Event> createTask({
    required String groupId,
    required String title,
    String? note,
    required DateTime dueAt,
    int? reminderTime,
    List<String>? recipients,
    bool notifyOwner = true,
    required String token,
  }) async {
    final res = await AuthenticatedHttpClient.post(
      Uri.parse(tasksUrl),
      headers: _authHeaders(token),
      body: jsonEncode({
        'groupId': groupId,
        'title': title,
        'note': note,
        'dueAt': dueAt.toUtc().toIso8601String(),
        'reminderTime': reminderTime ?? 0,
        'recipients': recipients ?? const <String>[],
        'notifyOwner': notifyOwner,
      }),
      client: _client,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Event.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }

    throw Exception('Failed to create task: ${res.body}');
  }

  @override
  Future<Event> getEventById(String eventId, String token) async {
    final url = '$baseUrl/${baseId(eventId)}';
    final headers = _authHeaders(token);

    debugPrint("ðŸ“¡ GET $url");
    debugPrint("ðŸ” Headers: $headers");

    final res = await AuthenticatedHttpClient.get(
      Uri.parse(url),
      headers: headers,
      client: _client,
    );

    debugPrint("ðŸ“¥ Status Code: ${res.statusCode}");
    debugPrint("ðŸ“¥ Response Body: ${res.body}");

    if (res.statusCode == 200) {
      return Event.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(
        '❌ Failed to fetch event – code: ${res.statusCode}, body: ${res.body}',
      );
    }
  }

  @override
  Future<Event> updateEvent(Event ev, String token) async {
    final ready = await _ensureRuleId(ev, token);
    final headers = _authHeaders(token);
    final payload = jsonEncode(ready.toBackendJson());

    final res = await AuthenticatedHttpClient.put(
      Uri.parse('$baseUrl/${baseId(ready.id)}'),
      headers: headers,
      body: payload,
      client: _client,
    );

    if (res.statusCode != 200) {
      debugPrint('ðŸ”´ Update failed: ${res.statusCode}');
      debugPrint('ðŸ“¦ Payload sent: $payload');
      throw Exception('Failed to update event: ${res.body}');
    }

    return Event.fromJson(jsonDecode(res.body));
  }

  @override
  Future<void> deleteEvent(String eventId, String token) async {
    final id = baseId(eventId);
    final url = '$baseUrl/$id';

    debugPrint('🌐 [API] DELETE → $url');
    final headers = _authHeaders(token);
    debugPrint('ðŸ” [API] Headers: $headers');

    final res = await AuthenticatedHttpClient.delete(
      Uri.parse(url),
      headers: headers,
      client: _client,
    );

    debugPrint('ðŸ“¥ [API] Response Status: ${res.statusCode}');
    debugPrint('ðŸ“¥ [API] Response Body: ${res.body}');

    if (res.statusCode != 200) {
      debugPrint('❌ [API] Delete failed');
      throw Exception('Failed to delete event');
    }

    debugPrint('✅ [API] Event deleted: $id');
  }

  @override
  Future<Event> markEventAsDone(
    String eventId, {
    required bool isDone,
    required String token,
  }) async {
    final res = await AuthenticatedHttpClient.patch(
      Uri.parse('$baseUrl/${baseId(eventId)}/done'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'isDone': isDone,
      }),
      client: _client,
    );

    if (res.statusCode == 200) {
      return Event.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to update event status');
    }
  }

  @override
  Future<List<Event>> getEventsByGroupId(String groupId, String token) async {
    final res = await AuthenticatedHttpClient.get(
      Uri.parse('$baseUrl/group/$groupId'),
      headers: _authHeaders(token),
      client: _client,
    );

    if (res.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(res.body);
      return jsonList.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch events for group $groupId');
    }
  }

  @override
  Future<List<Event>> getTasks({
    required String groupId,
    String? status,
    bool mine = false,
    DateTime? from,
    DateTime? to,
    required String token,
  }) async {
    final params = <String, String>{
      'groupId': groupId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (mine) 'mine': 'true',
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };

    final uri = Uri.parse(tasksUrl).replace(queryParameters: params);
    final res = await AuthenticatedHttpClient.get(
      uri,
      headers: _authHeaders(token),
      client: _client,
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch tasks: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final rawList = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic>
            ? (decoded['tasks'] ?? decoded['items'] ?? decoded['rows'] ?? [])
            : []);

    return List<Event>.from(
      (rawList as List).map(
        (item) => Event.fromJson((item as Map).cast<String, dynamic>()),
      ),
    );
  }
}
