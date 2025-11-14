import 'dart:convert';
import 'dart:typed_data';
// Add near the top of the file
import 'dart:ui' as ui;

import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

import 'i_time_tracking_api_client.dart';

String _detectLang() {
  final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
  return code == 'es' ? 'es' : 'en';
}

// Implements repository, wraps APi client
class TimeTrackingApiClient implements ITimeTrackingApiClient {
  TimeTrackingApiClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  String get _root => ApiConstants.baseUrl;

  Map<String, String> _headers(String token, {bool json = true}) => {
        'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  // Base path for time-tracking
  String _ttPath(String groupId) => '/groups/$groupId/time-tracking';

  @override
  Future<void> enable(String groupId, String token) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/enable');
    final res = await _client.post(uri, headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to enable time-tracking: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<void> disable(String groupId, String token) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/disable');
    final res = await _client.post(uri, headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to disable time-tracking: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<List<Worker>> listWorkers(String groupId, String token) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/workers');
    final res = await _client.get(uri, headers: _headers(token, json: false));

    if (res.statusCode == 200) {
      final raw = jsonDecode(res.body) as List;
      return raw.cast<Map<String, dynamic>>().map(Worker.fromJson).toList();
    }
    if (res.statusCode == 404) return const <Worker>[];
    throw Exception('Failed to list workers: ${res.statusCode} ${res.body}');
  }

  @override
  Future<Worker> createWorker(
      String groupId, Worker worker, String token) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/workers');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(worker.toCreateJson()),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create worker: ${res.statusCode} ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return Worker.fromJson(map);
  }

  @override
  Future<List<TimeEntry>> listTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) async {
    final qp = <String, String>{};
    if (from != null) qp['from'] = from.toUtc().toIso8601String();
    if (to != null) qp['to'] = to.toUtc().toIso8601String();
    if (workerId != null) qp['workerId'] = workerId;

    final uri = Uri.parse('$_root${_ttPath(groupId)}/time-entries')
        .replace(queryParameters: qp.isEmpty ? null : qp);

    final res = await _client.get(uri, headers: _headers(token, json: false));
    if (res.statusCode == 200) {
      final raw = jsonDecode(res.body) as List;
      return raw.cast<Map<String, dynamic>>().map(TimeEntry.fromJson).toList();
    }
    if (res.statusCode == 404) return const <TimeEntry>[];
    throw Exception(
        'Failed to list time entries: ${res.statusCode} ${res.body}');
  }

  @override
  Future<TimeEntry> createTimeEntry(
    String groupId,
    TimeEntry entry,
    String token,
  ) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/time-entries');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(entry.toCreateJson()),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
          'Failed to create time entry: ${res.statusCode} ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return TimeEntry.fromJson(map);
  }

  // @override
  // Future<Uint8List> exportExcel(String groupId, String token) async {
  //   final uri = Uri.parse('$_root${_ttPath(groupId)}/export');
  //   final res = await _client.get(uri, headers: _headers(token, json: false));
  //   if (res.statusCode == 200) {
  //     return res.bodyBytes;
  //   }
  //   throw Exception('Failed to export Excel: ${res.statusCode} ${res.body}');
  // }

  Future<Uint8List> exportExcel(String groupId, String token,
      {String? lang}) async {
    final qp = <String, String>{'lang': (lang ?? _detectLang())};

    final uri = Uri.parse('$_root${_ttPath(groupId)}/export')
        .replace(queryParameters: qp);

    final res = await _client.get(uri, headers: _headers(token, json: false));

    if (res.statusCode == 200) {
      return res.bodyBytes;
    }

    throw Exception('Failed to export Excel: ${res.statusCode} ${res.body}');
  }

  @override
  Future<Map<String, dynamic>> getWorkerTotals(
    String groupId,
    String token, {
    String? workerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/totals').replace(
      queryParameters: {
        if (workerId != null) 'workerId': workerId,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      // No entries found
      return {
        'totalHours': 0,
        'totalPay': 0,
        'currency': 'EUR',
      };
    } else {
      throw Exception('Failed to load worker totals: ${response.body}');
    }
  }

  @override
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token,
  ) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/workers/$workerId');
    final res = await _client.put(
      uri,
      headers: _headers(token),
      body: jsonEncode(worker.toCreateJson()), // reuse create JSON
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update worker: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return Worker.fromJson(map);
  }

  @override
  Future<TimeEntry> updateTimeEntry(
    String groupId,
    String entryId,
    TimeEntry entry,
    String token,
  ) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/time-entries/$entryId');
    final res = await _client.put(
      uri,
      headers: _headers(token),
      body: jsonEncode(entry.toCreateJson()), // same format as create
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to update time entry: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return TimeEntry.fromJson(map);
  }

  @override
  Future<void> deleteTimeEntry(
    String groupId,
    String entryId,
    String token,
  ) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/time-entries/$entryId');
    final res =
        await _client.delete(uri, headers: _headers(token, json: false));

    // Accept 204 No Content or 200 OK (in case server returns json)
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
          'Failed to delete time entry: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<int> purgeTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) async {
    final qp = <String, String>{};
    if (from != null) qp['from'] = from.toUtc().toIso8601String();
    if (to != null) qp['to'] = to.toUtc().toIso8601String();
    if (workerId != null) qp['workerId'] = workerId;

    final uri = Uri.parse('$_root${_ttPath(groupId)}/time-entries')
        .replace(queryParameters: qp.isEmpty ? null : qp);

    final res =
        await _client.delete(uri, headers: _headers(token, json: false));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['deletedCount'] as num?)?.toInt() ?? 0;
    }

    // 204 would be unusual for bulk delete (no count), but handle gracefully.
    if (res.statusCode == 204) return 0;

    throw Exception(
        'Failed to purge time entries: ${res.statusCode} ${res.body}');
  }

  @override
  Future<Uint8List> exportExcelFiltered(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) async {
    final qp = <String, String>{};
    if (from != null) qp['from'] = from.toUtc().toIso8601String();
    if (to != null) qp['to'] = to.toUtc().toIso8601String();
    if (workerId != null) qp['workerId'] = workerId;

    final uri = Uri.parse('$_root${_ttPath(groupId)}/export')
        .replace(queryParameters: qp.isEmpty ? null : qp);

    final res = await _client.get(uri, headers: _headers(token, json: false));
    if (res.statusCode == 200) return res.bodyBytes;

    throw Exception('Failed to export Excel: ${res.statusCode} ${res.body}');
  }
}
