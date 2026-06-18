import 'dart:convert';
import 'dart:typed_data';
// Add near the top of the file
import 'dart:ui' as ui;

import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/working_time_excel_import.dart';
import 'package:hexora/a-models/group_model/worker/working_time_history.dart';
import 'package:hexora/a-models/group_model/worker/working_time_import_instructions.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  Map<String, String> _headers(
    String token, {
    bool json = true,
    String accept = 'application/json',
  }) =>
      {
        'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json; charset=UTF-8',
        'Accept': accept,
      };

  // Base path for time-tracking
  String _ttPath(String groupId) => '/groups/$groupId/time-tracking';

  MediaType _excelMediaType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.xls')) {
      return MediaType('application', 'vnd.ms-excel');
    }
    return MediaType(
      'application',
      'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

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
  Future<List<Worker>> listWorkers(
    String groupId,
    String token, {
    WorkerStatus? status,
    String? month,
  }) async {
    final qp = <String, String>{};
    if (status != null) {
      qp['status'] = status == WorkerStatus.archived ? 'archived' : 'active';
    }
    if (month != null && month.trim().isNotEmpty) {
      qp['month'] = month.trim();
    }
    final uri = Uri.parse('$_root${_ttPath(groupId)}/workers')
        .replace(queryParameters: qp.isEmpty ? null : qp);
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

  @override
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
    String? month,
    DateTime? from,
    DateTime? to,
    double? advanceAmount,
  }) async {
    final effectiveAdvance =
        (advanceAmount != null && advanceAmount >= 0) ? advanceAmount : null;
    final uri = Uri.parse('$_root${_ttPath(groupId)}/totals').replace(
      queryParameters: {
        if (workerId != null) 'workerId': workerId,
        if (month != null && month.trim().isNotEmpty) 'month': month.trim(),
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        if (effectiveAdvance != null)
          'advanceAmount': effectiveAdvance.toStringAsFixed(2),
      },
    );

    final response = await _client.get(
      uri,
      headers: _headers(token, json: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      // No entries found
      return {
        'totalHours': 0,
        'totalPay': 0,
        'grossPay': 0,
        'advanceAmount': effectiveAdvance ?? 0,
        'netPay': 0,
        'currency': 'EUR',
      };
    } else {
      throw Exception('Failed to load worker totals: ${response.body}');
    }
  }

  Uri buildActiveWorkersTotalsUri(
    String groupId, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  }) {
    final qp = <String, String>{};
    if (from != null) qp['from'] = from.toUtc().toIso8601String();
    if (to != null) qp['to'] = to.toUtc().toIso8601String();
    if (year != null) qp['year'] = year.toString();
    if (month != null) qp['month'] = month.toString();
    return Uri.parse('$_root${_ttPath(groupId)}/totals/active-workers')
        .replace(queryParameters: qp.isEmpty ? null : qp);
  }

  Uri buildMonthlyPayrollHistoryUri(
    String groupId, {
    required DateTime from,
    required DateTime to,
    String? workerId,
  }) {
    final qp = <String, String>{
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      if (workerId != null && workerId.trim().isNotEmpty)
        'workerId': workerId.trim(),
    };
    return Uri.parse('$_root${_ttPath(groupId)}/totals/history')
        .replace(queryParameters: qp);
  }

  Uri buildWorkingTimeHistoryUri(
    String groupId, {
    required DateTime from,
    required DateTime to,
    required String granularity,
    String? workerId,
  }) {
    final qp = <String, String>{
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'granularity': granularity,
      if (workerId != null && workerId.trim().isNotEmpty)
        'workerId': workerId.trim(),
    };
    return Uri.parse('$_root${_ttPath(groupId)}/totals/working-time-history')
        .replace(queryParameters: qp);
  }

  @override
  Future<Map<String, dynamic>> getActiveWorkersTotals(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  }) async {
    final uri = buildActiveWorkersTotalsUri(
      groupId,
      from: from,
      to: to,
      year: year,
      month: month,
    );

    final res = await _client.get(uri, headers: _headers(token, json: false));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 404) {
      return {
        'period': {'from': null, 'to': null},
        'activeWorkersCount': 0,
        'entriesCount': 0,
        'totalMinutes': 0,
        'totalHours': 0,
        'totalPay': 0,
        'currency': null,
        'totalsByCurrency': const [],
      };
    }
    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to load active workers totals',
    );
  }

  @override
  Future<Map<String, dynamic>> getMonthlyPayrollHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String? workerId,
  }) async {
    final uri = buildMonthlyPayrollHistoryUri(
      groupId,
      from: from,
      to: to,
      workerId: workerId,
    );

    final res = await _client.get(uri, headers: _headers(token, json: false));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to load payroll history',
    );
  }

  @override
  Future<WorkingTimeHistoryResponse> getWorkingTimeHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String granularity = 'day',
    String? workerId,
  }) async {
    final uri = buildWorkingTimeHistoryUri(
      groupId,
      from: from,
      to: to,
      granularity: granularity,
      workerId: workerId,
    );

    final res = await _client.get(uri, headers: _headers(token, json: false));
    if (res.statusCode == 200) {
      return WorkingTimeHistoryResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to load working time history',
    );
  }

  @override
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token, {
    String? month,
    DateTime? from,
    DateTime? to,
  }) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/workers/$workerId');
    final payload = worker.toUpdateJson();
    if (month != null && month.trim().isNotEmpty) {
      payload['month'] = month.trim();
    } else {
      if (from != null) payload['from'] = from.toUtc().toIso8601String();
      if (to != null) payload['to'] = to.toUtc().toIso8601String();
    }
    final res = await _client.put(
      uri,
      headers: _headers(token),
      body: jsonEncode(payload),
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
    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to export Excel',
    );
  }

  @override
  Future<Uint8List> previewPayrollPdf(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
    String? lang,
    double? advanceAmount,
  }) async {
    final normalizedLang =
        (lang ?? _detectLang()).toLowerCase() == 'es' ? 'es' : 'en';

    final qp = <String, String>{'lang': normalizedLang};
    if (from != null) qp['from'] = from.toUtc().toIso8601String();
    if (to != null) qp['to'] = to.toUtc().toIso8601String();
    if (workerId != null && workerId.trim().isNotEmpty) {
      qp['workerId'] = workerId.trim();
    }
    if (advanceAmount != null && advanceAmount >= 0) {
      qp['advanceAmount'] = advanceAmount.toStringAsFixed(2);
    }

    final uri = Uri.parse('$_root${_ttPath(groupId)}/export/pdf/preview')
        .replace(queryParameters: qp);

    final res = await _client.get(
      uri,
      headers: _headers(
        token,
        json: false,
        accept: 'application/pdf',
      ),
    );

    if (res.statusCode == 200) return res.bodyBytes;

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to preview payroll PDF',
    );
  }

  @override
  Future<Uint8List> downloadExcelImportTemplate(
    String groupId,
    String token, {
    required String month,
  }) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/import-excel/template')
        .replace(queryParameters: {'month': month});

    final res = await _client.get(
      uri,
      headers: _headers(
        token,
        json: false,
        accept:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,application/octet-stream',
      ),
    );

    if (res.statusCode == 200) {
      return res.bodyBytes;
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to download Excel import template',
    );
  }

  @override
  Future<WorkingTimeImportInstructions> getImportInstructions(
    String groupId,
    String token,
  ) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/import/instructions');
    final res = await _client.get(uri, headers: _headers(token, json: false));
    if (res.statusCode == 200) {
      return WorkingTimeImportInstructions.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to load time-tracking import instructions',
    );
  }

  @override
  Future<WorkingTimeExcelImportPreview> previewExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_root${_ttPath(groupId)}/import-excel/preview'),
    );
    req.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    req.fields['workerId'] = workerId;
    req.fields['month'] = month;
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: _excelMediaType(fileName),
      ),
    );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      return WorkingTimeExcelImportPreview.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to preview Excel import',
    );
  }

  @override
  Future<WorkingTimeExcelImportConfirmResult> confirmExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required List<WorkingTimeExcelImportEntry> entries,
  }) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/import-excel/confirm');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'workerId': workerId,
        'month': month,
        'entries':
            entries.map((entry) => entry.toJson()).toList(growable: false),
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = res.body.trim();
      if (body.isEmpty) {
        return WorkingTimeExcelImportConfirmResult(
          importedCount: entries.length,
          requestId: null,
          raw: const <String, dynamic>{},
        );
      }
      return WorkingTimeExcelImportConfirmResult.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
        fallbackImportedCount: entries.length,
      );
    }

    if (res.statusCode == 204) {
      return WorkingTimeExcelImportConfirmResult(
        importedCount: entries.length,
        requestId: null,
        raw: const <String, dynamic>{},
      );
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to confirm Excel import',
    );
  }

  @override
  Future<WorkingTimeExcelImportPreview> previewJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    required List<Map<String, dynamic>> entries,
  }) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/import-json/preview');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'month': month,
        if (workerId != null && workerId.trim().isNotEmpty)
          'workerId': workerId,
        'entries': entries,
      }),
    );

    if (res.statusCode == 200) {
      return WorkingTimeExcelImportPreview.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to preview JSON import',
    );
  }

  @override
  Future<Map<String, dynamic>> getTelegramImportSource(
    String groupId,
    String token, {
    required String topicName,
  }) async {
    final uri = Uri.parse(
      '$_root${_ttPath(groupId)}/import-telegram/source',
    ).replace(queryParameters: {'topicName': topicName});
    final res = await _client.get(uri, headers: _headers(token));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to find Telegram import source',
    );
  }

  @override
  Future<Map<String, dynamic>> previewTelegramImport(
    String groupId,
    String token, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/import-telegram/preview');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to preview Telegram time tracking import',
    );
  }

  @override
  Future<WorkingTimeExcelImportConfirmResult> confirmJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    String? duplicateStrategy,
    required List<Map<String, dynamic>> entries,
  }) async {
    final uri = Uri.parse('$_root${_ttPath(groupId)}/import-json/confirm');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'month': month,
        if (workerId != null && workerId.trim().isNotEmpty)
          'workerId': workerId,
        if (duplicateStrategy != null && duplicateStrategy.trim().isNotEmpty)
          'duplicateStrategy': duplicateStrategy,
        'entries': entries,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = res.body.trim();
      if (body.isEmpty) {
        return WorkingTimeExcelImportConfirmResult(
          importedCount: entries.length,
          requestId: null,
          raw: const <String, dynamic>{},
        );
      }
      return WorkingTimeExcelImportConfirmResult.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
        fallbackImportedCount: entries.length,
      );
    }

    if (res.statusCode == 204) {
      return WorkingTimeExcelImportConfirmResult(
        importedCount: entries.length,
        requestId: null,
        raw: const <String, dynamic>{},
      );
    }

    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: 'Failed to confirm JSON import',
    );
  }
}
