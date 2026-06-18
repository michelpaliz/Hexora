import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/statements/models/statement_expense_suggestion.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/statements/models/statement_entries_page.dart';
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

String _dateOnly(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

class StatementsApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/statements'
      : '${ApiConstants.baseUrl}/api/statements';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool json = true}) {
    return AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: json,
      extra: json
          ? const {'Content-Type': 'application/json; charset=UTF-8'}
          : null,
    );
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

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  Future<Map<String, dynamic>> importStatement({
    required List<int> bytes,
    required String filename,
    String? groupId,
  }) async {
    final uri = _u(
      '/import',
      (groupId != null && groupId.trim().isNotEmpty)
          ? <String, String>{'groupId': groupId.trim()}
          : null,
    );
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers(json: false));
    if (groupId != null && groupId.trim().isNotEmpty) {
      req.fields['groupId'] = groupId.trim();
    }
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
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> listImports() async {
    final uri = _u();
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
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

  Future<http.Response> exportEntriesExcel({
    required String groupId,
    int? year,
    String? dateFrom,
    String? dateTo,
    String amountType = 'all',
    double? minAmount,
    double? maxAmount,
    String? clientProviderQuery,
    String? sort,
  }) async {
    final uri = _u('/entries/export-excel');
    final body = <String, dynamic>{
      'groupId': groupId,
      if (year != null) 'year': year,
      if (dateFrom != null && dateFrom.trim().isNotEmpty)
        'dateFrom': dateFrom.trim(),
      if (dateTo != null && dateTo.trim().isNotEmpty) 'dateTo': dateTo.trim(),
      'amountType': amountType.trim().isEmpty ? 'all' : amountType.trim(),
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
      if (clientProviderQuery != null && clientProviderQuery.trim().isNotEmpty)
        'clientProviderQuery': clientProviderQuery.trim(),
      if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
    };
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    _decode<void>(
      r,
      url: uri,
      method: 'POST',
      map: (_) {},
    );
    return r;
  }

  Future<void> deleteBatch(String batchId) async {
    final uri = _u('/$batchId');
    final r =
        await AuthenticatedHttpClient.delete(uri, headers: await _headers());
    _decode<void>(
      r,
      url: uri,
      method: 'DELETE',
      map: (_) {},
    );
  }

  Future<Map<String, dynamic>> reprocessBatch(String batchId) async {
    final uri = _u('/$batchId/reprocess');
    final r =
        await AuthenticatedHttpClient.post(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> batchEntries(
    String batchId, {
    String? order,
  }) async {
    final query = <String, String>{
      if (order != null && order.isNotEmpty) 'order': order,
    };
    final uri = _u('/$batchId/entries', query.isEmpty ? null : query);
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
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
    String? order,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (year != null) 'year': year.toString(),
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      if (order != null && order.isNotEmpty) 'order': order,
    };
    final uri = _u('/$batchId/entries', query);
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (kDebugMode) {
          final type = j.runtimeType;
          final keys = j is Map ? j.keys.join(',') : '-';
          final entriesType =
              (j is Map) ? (j['entries']?.runtimeType.toString() ?? '-') : '-';
          debugPrint(
              '[StatementsApi] entriesPaged type=$type keys=$keys entriesType=$entriesType');
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
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
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
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (kDebugMode) {
          final keys = j is Map ? j.keys.join(',') : '-';
          final years = (j is Map && j['years'] is List)
              ? (j['years'] as List).length
              : 0;
          final months = (j is Map && j['months'] is List)
              ? (j['months'] as List).length
              : 0;
          final topMerchants = j is Map ? j['topMerchants'] : null;
          final topExpense =
              (topMerchants is Map && topMerchants['expense'] is List)
                  ? (topMerchants['expense'] as List).length
                  : 0;
          final topIncome =
              (topMerchants is Map && topMerchants['income'] is List)
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
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
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
    final r =
        await AuthenticatedHttpClient.post(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> reminderSettings({
    required String batchId,
  }) async {
    final uri = _u('/$batchId/reminder-settings');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
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
    final r = await AuthenticatedHttpClient.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'PUT',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> suggestClients(String entryId) async {
    final uri = _u('/entries/$entryId/suggest-clients');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> suggestInvoices(
    String entryId, {
    String? type,
    double? tolerance,
    int? limit,
    String? groupId,
  }) async {
    final query = <String, String>{
      if (type != null && type.isNotEmpty) 'type': type,
      if (tolerance != null) 'tolerance': tolerance.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
    };
    final uri = _u(
      '/entries/$entryId/suggest-invoices',
      query.isEmpty ? null : query,
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<StatementExpenseSuggestion>> suggestExpenses(
    String entryId, {
    double? tolerance,
    int? limit,
    String? groupId,
  }) async {
    final query = <String, String>{
      if (tolerance != null) 'tolerance': tolerance.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
    };
    final uri = _u(
      '/entries/$entryId/suggest-expenses',
      query.isEmpty ? null : query,
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<List<StatementExpenseSuggestion>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        final items = (j is Map && j['suggestions'] is List)
            ? j['suggestions'] as List
            : j is List
                ? j
                : const <dynamic>[];
        return items
            .whereType<Map>()
            .map(
              (item) => StatementExpenseSuggestion.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
      },
    );
  }

  Future<Map<String, dynamic>> aiMatchSuggestions(
    String entryId, {
    String direction = 'auto',
    String? groupId,
    int maxCombinationSize = 3,
    int limit = 12,
    double tolerance = 0.05,
    int maxWindowDays = 180,
    String method = 'auto',
    bool includeLinked = true,
  }) async {
    final uri = _u('/entries/$entryId/ai-match-suggestions');
    final payload = <String, dynamic>{
      'direction': direction,
      'groupId': groupId,
      'maxCombinationSize': maxCombinationSize,
      'limit': limit,
      'tolerance': tolerance,
      'maxWindowDays': maxWindowDays,
      'method': method,
      'includeLinked': includeLinked,
    }..removeWhere((key, value) {
        if (value == null) return true;
        if (value is String) return value.trim().isEmpty;
        return false;
      });
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<void> linkEntryClient(
      {required String entryId, String? clientId}) async {
    final uri = _u('/entries/$entryId/client');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'clientId': clientId}),
    );
    _decode<void>(
      r,
      url: uri,
      method: 'POST',
      map: (_) {},
    );
  }

  Future<Map<String, dynamic>> updateEntryNotes({
    required String entryId,
    required String? notes,
  }) async {
    final uri = _u('/entries/$entryId/notes');
    final r = await AuthenticatedHttpClient.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode({'notes': notes}),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'PATCH',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<StatementEntriesPage> fetchStatementEntries({
    required String groupId,
    int page = 1,
    int size = 50,
    String? cursor,
    int? year,
    DateTime? dateFrom,
    DateTime? dateTo,
    String amountType = 'all',
    double? minAmount,
    double? maxAmount,
    String? clientProviderQuery,
    String sort = 'date_desc',
  }) async {
    final boundedSize = size < 1 ? 50 : (size > 200 ? 200 : size);
    final q = <String, String>{
      'groupId': groupId,
      'page': page.toString(),
      'size': boundedSize.toString(),
      if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
      if (year != null) 'year': year.toString(),
      if (dateFrom != null) 'date_from': _dateOnly(dateFrom),
      if (dateTo != null) 'date_to': _dateOnly(dateTo),
      if (amountType.trim().isNotEmpty) 'amountType': amountType.trim(),
      if (minAmount != null) 'minAmount': minAmount.toString(),
      if (maxAmount != null) 'maxAmount': maxAmount.toString(),
      if (clientProviderQuery != null && clientProviderQuery.trim().isNotEmpty)
        'clientProviderQuery': clientProviderQuery.trim(),
      if (sort.trim().isNotEmpty) 'sort': sort.trim(),
    };

    final uri = _u('/entries', q);
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<StatementEntriesPage>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        final map = (j is Map)
            ? Map<String, dynamic>.from(j)
            : const <String, dynamic>{};
        final rawItems = map['items'];
        final items = (rawItems is List)
            ? rawItems
                .whereType<Map>()
                .map((e) => StatementEntry(Map<String, dynamic>.from(e)))
                .toList(growable: false)
            : const <StatementEntry>[];
        final timingRaw = map['timing'];
        StatementEntriesTiming? timing;
        if (timingRaw is Map) {
          timing = StatementEntriesTiming(
            dbMs: _readInt(timingRaw['dbMs']),
            totalMs: _readInt(timingRaw['totalMs']),
          );
        }
        return StatementEntriesPage(
          items: items,
          page: _readInt(map['page']) ?? page,
          size: _readInt(map['size']) ?? boundedSize,
          total: _readInt(map['total']) ?? items.length,
          totalPages: _readInt(map['totalPages']) ?? 1,
          nextCursor: map['nextCursor']?.toString(),
          timing: timing,
        );
      },
    );
  }

  Future<Map<String, dynamic>> linkEntryInvoice({
    required String entryId,
    String? invoiceId,
    List<String>? invoiceIds,
  }) async {
    final uri = _u('/entries/$entryId/invoice');
    final payload = <String, dynamic>{};
    if (invoiceIds != null) {
      payload['invoiceIds'] = invoiceIds;
    } else {
      payload['invoiceId'] = invoiceId;
    }
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> bulkLinkEntryInvoices({
    required List<Map<String, dynamic>> links,
  }) async {
    final uri = _u('/entries/invoices/bulk-link');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{'links': links}),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> linkEntryInvoiceExpense({
    required String entryId,
    String? invoiceId,
    List<String>? invoiceIds,
  }) async {
    final uri = _u('/entries/$entryId/invoice/expense');
    final payload = <String, dynamic>{};
    if (invoiceIds != null) {
      payload['invoiceIds'] = invoiceIds;
    } else {
      payload['invoiceId'] = invoiceId;
    }
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }
}
