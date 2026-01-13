import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class ExpensesApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  ExpensesApiException({
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
    return 'Expenses API ($statusCode) $method $url: $message$body';
  }
}

class ExpensesApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/expenses'
      : '${ApiConstants.baseUrl}/api/expenses';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await TokenService.loadToken();
    return <String, String>{
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  T _decode<T>(
    http.Response r, {
    required Uri url,
    required String method,
    required T Function(dynamic json) map,
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

    final ex = ExpensesApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    if (kDebugMode) debugPrint(ex.toString());
    throw ex;
  }

  Future<Map<String, dynamic>> uploadExpense({
    required List<int> bytes,
    required String filename,
    required String vendorName,
    required String issueDate,
    required String total,
    String? groupId,
    String? vendorTaxId,
    String? invoiceNumber,
    String? dueDate,
    String? taxTotal,
    String? currency,
    String? notes,
    String? clientId,
    String? statementEntryId,
    String? providerId,
    List<Map<String, dynamic>>? lines,
  }) async {
    final uri = _u();
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers(json: false));
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
    req.fields['vendorName'] = vendorName;
    req.fields['issueDate'] = issueDate;
    if (total.isNotEmpty) {
      req.fields['total'] = total;
    }
    if (groupId != null && groupId.isNotEmpty) {
      req.fields['groupId'] = groupId;
    }
    if (vendorTaxId != null && vendorTaxId.isNotEmpty) {
      req.fields['vendorTaxId'] = vendorTaxId;
    }
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      req.fields['invoiceNumber'] = invoiceNumber;
    }
    if (dueDate != null && dueDate.isNotEmpty) {
      req.fields['dueDate'] = dueDate;
    }
    if (taxTotal != null && taxTotal.isNotEmpty) {
      req.fields['taxTotal'] = taxTotal;
    }
    if (currency != null && currency.isNotEmpty) {
      req.fields['currency'] = currency;
    }
    if (notes != null && notes.isNotEmpty) {
      req.fields['notes'] = notes;
    }
    if (clientId != null && clientId.isNotEmpty) {
      req.fields['clientId'] = clientId;
    }
    if (statementEntryId != null && statementEntryId.isNotEmpty) {
      req.fields['statementEntryId'] = statementEntryId;
    }
    if (providerId != null && providerId.isNotEmpty) {
      req.fields['providerId'] = providerId;
    }
    if (lines != null && lines.isNotEmpty) {
      req.fields['lines'] = jsonEncode(lines);
    }
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

  Future<List<Map<String, dynamic>>> list({
    int page = 1,
    int size = 50,
    String? groupId,
    String? providerId,
    String? clientId,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (groupId != null && groupId.trim().isNotEmpty) {
      params['groupId'] = groupId.trim();
    }
    if (providerId != null && providerId.trim().isNotEmpty) {
      params['providerId'] = providerId.trim();
    }
    if (clientId != null && clientId.trim().isNotEmpty) {
      params['clientId'] = clientId.trim();
    }
    final uri = _u('', params);
    final r = await http.get(uri, headers: await _headers());
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
        if (j is Map) {
          final items = j['items'] ??
              j['data'] ??
              j['results'] ??
              j['expenses'];
          if (items is List) {
            return items
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> updateExpense({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final uri = _u('/$id');
    final r = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'PUT',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<void> deleteExpense(String id) async {
    final uri = _u('/$id');
    final r = await http.delete(uri, headers: await _headers());
    _decode<void>(
      r,
      url: uri,
      method: 'DELETE',
      map: (_) => null,
    );
  }

  Future<void> linkExpense({
    required String expenseId,
    required String entryId,
  }) async {
    final uri = _u('/link');
    final r = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'expenseId': expenseId,
        'entryId': entryId,
      }),
    );
    _decode<void>(
      r,
      url: uri,
      method: 'POST',
      map: (_) => null,
    );
  }

  Future<Map<String, dynamic>> fetchExpense(String id) async {
    final uri = _u('/$id');
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }
}
