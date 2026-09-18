import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/models/event/model/event.dart';
import 'package:hexora/data/auth/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/data/config/api_constants.dart';
import 'package:hexora/data/group_management/event/api/i_event_api_client.dart';
import 'package:hexora/data/group_management/event/string_utils.dart';
import 'package:hexora/data/group_management/recurrence_rule/recurrence_rule_api_client.dart';
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
    if (ev.recurrence_rule == null) return ev;

    // Case-insensitive hex check for 24-char Mongo ObjectId
    final isObjectId = RegExp(r'^[a-f0-9]{24}$', caseSensitive: false)
        .hasMatch(ev.recurrence_rule!.id);
    if (isObjectId) return ev;

    final created = await _ruleService.createRule(ev.recurrence_rule!);
    return ev.copyWith(recurrence_rule: created);
  }

  @override
  Future<Event> createEvent(Event eventData, String token) async {
    final readyEvent = await _ensureRuleId(eventData, token);
    final headers = _authHeaders(token);
    final body = jsonEncode(readyEvent.toBackendJson());
    final uri = Uri.parse(baseUrl);

    _debugEventApi(method: 'POST', uri: uri);

    final res = await AuthenticatedHttpClient.post(
      uri,
      headers: headers,
      body: body,
      client: _client,
    );
    _debugEventApi(method: 'POST', uri: uri, statusCode: res.statusCode);

    if (res.statusCode == 201) {
      return Event.fromJson(jsonDecode(res.body));
    }

    throw Exception('Failed to create event: ${res.body}');
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

    final uri = Uri.parse(url);
    _debugEventApi(method: 'GET', uri: uri);

    final res = await AuthenticatedHttpClient.get(
      uri,
      headers: headers,
      client: _client,
    );

    _debugEventApi(method: 'GET', uri: uri, statusCode: res.statusCode);

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
    final uri = Uri.parse('$baseUrl/${baseId(ready.id)}');

    final res = await AuthenticatedHttpClient.put(
      uri,
      headers: headers,
      body: payload,
      client: _client,
    );

    if (res.statusCode != 200) {
      _debugEventApi(method: 'PUT', uri: uri, statusCode: res.statusCode);
      throw Exception('Failed to update event: ${res.body}');
    }

    return Event.fromJson(jsonDecode(res.body));
  }

  @override
  Future<void> deleteEvent(String eventId, String token) async {
    final id = baseId(eventId);
    final url = '$baseUrl/$id';
    final uri = Uri.parse(url);

    final headers = _authHeaders(token);
    _debugEventApi(method: 'DELETE', uri: uri);

    final res = await AuthenticatedHttpClient.delete(
      uri,
      headers: headers,
      client: _client,
    );

    _debugEventApi(method: 'DELETE', uri: uri, statusCode: res.statusCode);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete event');
    }
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
  Future<Map<String, dynamic>> getEvidenceUploadSas(
    String eventId, {
    required String mimeType,
    required String token,
  }) async {
    final res = await AuthenticatedHttpClient.post(
      Uri.parse('$baseUrl/${baseId(eventId)}/evidence/upload-sas'),
      headers: _authHeaders(token),
      body: jsonEncode({'mimeType': mimeType}),
      client: _client,
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create evidence upload SAS: ${res.body}');
  }

  @override
  Future<Event> addEvidencePhoto(
    String eventId, {
    required String blobName,
    String? mimeType,
    String photoType = 'general',
    required String token,
  }) async {
    final res = await AuthenticatedHttpClient.post(
      Uri.parse('$baseUrl/${baseId(eventId)}/evidence/photos'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'blobName': blobName,
        if (mimeType != null) 'mimeType': mimeType,
        'photoType': photoType,
      }),
      client: _client,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Event.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to register evidence photo: ${res.body}');
  }

  @override
  Future<String> getEvidenceReadSas(
    String eventId, {
    required String blobName,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/${baseId(eventId)}/evidence/read-sas')
        .replace(queryParameters: {'blobName': blobName});
    final res = await AuthenticatedHttpClient.get(
      uri,
      headers: _authHeaders(token),
      client: _client,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['url'] as String? ?? '';
    }
    throw Exception('Failed to create evidence read SAS: ${res.body}');
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

@visibleForTesting
String? formatEventApiDiagnostic({
  required String method,
  required Uri uri,
  int? statusCode,
}) {
  if (!kDebugMode) return null;

  return <String>[
    '[EventApiClient] $method ${_redactedEventPath(uri)}',
    if (statusCode != null) 'status=$statusCode',
  ].join(' ');
}

void _debugEventApi({
  required String method,
  required Uri uri,
  int? statusCode,
}) {
  final diagnostic = formatEventApiDiagnostic(
    method: method,
    uri: uri,
    statusCode: statusCode,
  );
  if (diagnostic != null) debugPrint(diagnostic);
}

String _redactedEventPath(Uri uri) {
  final segments = uri.pathSegments;
  final eventsIndex = segments.indexOf('events');
  if (eventsIndex == -1 || eventsIndex == segments.length - 1) {
    return '/events';
  }

  final action = segments[eventsIndex + 1];
  if (action == 'tasks') return '/events/tasks';
  if (action == 'group') return '/events/group/[redacted]';
  if (segments.length > eventsIndex + 2 &&
      segments[eventsIndex + 2] == 'done') {
    return '/events/[redacted]/done';
  }
  return '/events/[redacted]';
}
