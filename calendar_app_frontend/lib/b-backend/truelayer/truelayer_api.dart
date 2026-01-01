import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class TrueLayerApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;
  final Map<String, String>? responseHeaders;

  TrueLayerApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.method,
    required this.responseBody,
    required this.responseHeaders,
  });

  @override
  String toString() {
    final body = (responseBody == null || responseBody!.trim().isEmpty)
        ? ''
        : '\nbody: ${responseBody!.trim()}';
    return 'TrueLayer API ($statusCode) $method $url: $message$body';
  }
}

class TrueLayerApi {
  // ApiConstants.baseUrl already includes a trailing `/api` in most envs.
  // TrueLayer endpoints are rooted at `/api/truelayer/...`, so avoid `/api/api/...`.
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/truelayer'
      : '${ApiConstants.baseUrl}/api/truelayer';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers() async {
    final token = await TokenService.loadToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated (missing access token)');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
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

    final ex = TrueLayerApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
      responseHeaders: r.headers,
    );
    if (kDebugMode) debugPrint(ex.toString());
    throw ex;
  }

  Future<Map<String, dynamic>> connect() async {
    final uri = _u('/connect');
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> accounts() async {
    final uri = _u('/accounts');
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) return <String, dynamic>{'accounts': j};
        return (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{};
      },
    );
  }

  Future<Map<String, dynamic>> transactions({
    required String accountId,
    required String from,
    required String to,
  }) async {
    final uri = _u('/transactions', {
      'accountId': accountId,
      'from': from,
      'to': to,
    });
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) return <String, dynamic>{'transactions': j};
        return (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{};
      },
    );
  }
}
