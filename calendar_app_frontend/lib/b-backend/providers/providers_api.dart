import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class ProvidersApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  ProvidersApiException({
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
    return 'Providers API ($statusCode) $method $url: $message$body';
  }
}

class ProvidersApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/providers'
      : '${ApiConstants.baseUrl}/api/providers';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Map<String, String> _headers({bool json = true}) => <String, String>{
        if (json) 'Content-Type': 'application/json',
      };

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

    final ex = ProvidersApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    if (kDebugMode) debugPrint(ex.toString());
    throw ex;
  }

  Future<List<Map<String, dynamic>>> list({String? groupId}) async {
    final uri = _u(
      '',
      (groupId != null && groupId.trim().isNotEmpty)
          ? <String, String>{'groupId': groupId.trim()}
          : null,
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    if (kDebugMode) {
      debugPrint(
        '[ProvidersApi] GET $uri -> ${r.statusCode} ${r.body}',
      );
    }
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
          final items = j['providers'] ?? j['data'] ?? j['items'] ?? j['results'];
          if (items is List) {
            return items
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> create({
    required String name,
    String? taxId,
    String? email,
    String? phone,
    Map<String, dynamic>? address,
    String? notes,
    String? groupId,
  }) async {
    final uri = _u();
    final body = <String, dynamic>{
      'name': name,
      if (taxId != null) 'taxId': taxId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (groupId != null && groupId.trim().isNotEmpty)
        'groupId': groupId.trim(),
    };
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> update({
    required String id,
    required String name,
    String? taxId,
    String? email,
    String? phone,
    Map<String, dynamic>? address,
    String? notes,
  }) async {
    final uri = _u('/$id');
    final body = <String, dynamic>{
      'name': name,
      if (taxId != null) 'taxId': taxId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };
    final r = await AuthenticatedHttpClient.put(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'PUT',
      map: (j) => (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<void> delete(String id) async {
    final uri = _u('/$id');
    final r = await AuthenticatedHttpClient.delete(uri, headers: _headers());
    _decode<void>(
      r,
      url: uri,
      method: 'DELETE',
      map: (_) {},
    );
  }
}
