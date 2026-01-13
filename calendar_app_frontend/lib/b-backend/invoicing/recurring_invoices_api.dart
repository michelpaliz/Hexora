import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class RecurringInvoicesApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  RecurringInvoicesApiException({
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
    return 'RecurringInvoices API ($statusCode) $method $url: $message$body';
  }
}

class RecurringInvoicesApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/recurring-invoices'
      : '${ApiConstants.baseUrl}/api/recurring-invoices';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers() async {
    final token = await TokenService.loadToken();
    return <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
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

    final ex = RecurringInvoicesApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    if (kDebugMode) debugPrint(ex.toString());
    throw ex;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final uri = _u();
    final r = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
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

  Future<List<Map<String, dynamic>>> list({
    String? groupId,
    String? status,
  }) async {
    final query = <String, String>{
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final uri = _u('', query.isEmpty ? null : query);
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (j is Map && j['items'] is List) {
          return (j['items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> preview(Map<String, dynamic> payload) async {
    final uri = _u('/preview');
    final r = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> cancel(String id) async {
    final uri = _u('/$id/cancel');
    final r = await http.post(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> run() async {
    final uri = _u('/run');
    final r = await http.post(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }
}
