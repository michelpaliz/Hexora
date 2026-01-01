import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class StatementsApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  StatementsApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.method,
    required this.responseBody,
  });

  @override
  String toString() {
    final body = (responseBody == null || responseBody!.trim().isEmpty)
        ? ''
        : '\nbody: ${responseBody!.trim()}';
    return 'Statements API ($statusCode) $method $url: $message$body';
  }
}

class StatementsApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/statements'
      : '${ApiConstants.baseUrl}/api/statements';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await TokenService.loadToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated (missing access token)');
    }
    return {
      if (json) 'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  T _decode<T>(
    http.Response r, {
    required Uri url,
    required String method,
    required T Function(dynamic) map,
  }) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }

    if (ok) return map(body);

    String msg = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      msg = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      msg = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body.trim();
    }

    final ex = StatementsApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    if (kDebugMode) debugPrint(ex.toString());
    throw ex;
  }

  Future<Map<String, dynamic>> importStatement({
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = _u('/import');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers(json: false));
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> listImports() async {
    final uri = _u();
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (j is Map && j['batches'] is List) {
          return (j['batches'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  Future<void> deleteBatch(String batchId) async {
    final uri = _u('/$batchId');
    final r = await http.delete(uri, headers: await _headers());
    _decode<void>(
      r,
      url: uri,
      method: 'DELETE',
      map: (_) => null,
    );
  }

  Future<Map<String, dynamic>> reprocessBatch(String batchId) async {
    final uri = _u('/$batchId/reprocess');
    final r = await http.post(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> batchEntries(String batchId) async {
    final uri = _u('/$batchId/entries');
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (j is Map && j['entries'] is List) {
          return (j['entries'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> batchEntriesPaged({
    required String batchId,
    required int page,
    required int size,
    int? year,
    String? dateFrom,
    String? dateTo,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (year != null) 'year': year.toString(),
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final uri = _u('/$batchId/entries', query);
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (kDebugMode) {
          final type = j.runtimeType;
          final keys = j is Map ? j.keys.join(',') : '-';
          final entriesType = (j is Map) ? (j['entries']?.runtimeType.toString() ?? '-') : '-';
          debugPrint('[StatementsApi] entriesPaged type=$type keys=$keys entriesType=$entriesType');
        }
        return (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{};
      },
    );
  }

  Future<Map<String, dynamic>> batchSummary({
    required String batchId,
    required String group,
    int? year,
    String? dateFrom,
    String? dateTo,
  }) async {
    final query = <String, String>{
      'group': group,
      if (year != null) 'year': year.toString(),
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final uri = _u('/$batchId/summary', query);
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> analyticsSummary({
    required String batchId,
    int? year,
    int? month,
    int? top,
    String? dateFrom,
    String? dateTo,
  }) async {
    final query = <String, String>{
      if (year != null) 'year': year.toString(),
      if (month != null) 'month': month.toString(),
      if (top != null) 'top': top.toString(),
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final uri = _u('/$batchId/summary', query);
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (kDebugMode) {
          final keys = j is Map ? j.keys.join(',') : '-';
          final years = (j is Map && j['years'] is List) ? (j['years'] as List).length : 0;
          final months = (j is Map && j['months'] is List) ? (j['months'] as List).length : 0;
          final topMerchants = j is Map ? j['topMerchants'] : null;
          final topExpense = (topMerchants is Map && topMerchants['expense'] is List)
              ? (topMerchants['expense'] as List).length
              : 0;
          final topIncome = (topMerchants is Map && topMerchants['income'] is List)
              ? (topMerchants['income'] as List).length
              : 0;
          debugPrint(
            '[StatementsApi] analyticsSummary keys=$keys years=$years months=$months '
            'topExpense=$topExpense topIncome=$topIncome',
          );
        }
        return (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{};
      },
    );
  }

  Future<Map<String, dynamic>> batchStatus({
    required String batchId,
    int? threshold,
  }) async {
    final query = <String, String>{
      if (threshold != null) 'threshold': threshold.toString(),
    };
    final uri = _u('/$batchId/status', query);
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> notifyStale({
    required String batchId,
    int? threshold,
  }) async {
    final query = <String, String>{
      if (threshold != null) 'threshold': threshold.toString(),
    };
    final uri = _u('/$batchId/notify-stale', query);
    final r = await http.post(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> reminderSettings({
    required String batchId,
  }) async {
    final uri = _u('/$batchId/reminder-settings');
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> updateReminderSettings({
    required String batchId,
    required bool enabled,
    int? thresholdDays,
  }) async {
    final uri = _u('/$batchId/reminder-settings');
    final body = <String, dynamic>{
      'enabled': enabled,
      if (thresholdDays != null) 'thresholdDays': thresholdDays,
    };
    final r = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'PUT',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> suggestClients(String entryId) async {
    final uri = _u('/entries/$entryId/suggest-clients');
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  Future<void> linkEntryClient({required String entryId, String? clientId}) async {
    final uri = _u('/entries/$entryId/client');
    final r = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'clientId': clientId}),
    );
    _decode<void>(
      r,
      url: uri,
      method: 'POST',
      map: (_) => null,
    );
  }
}
