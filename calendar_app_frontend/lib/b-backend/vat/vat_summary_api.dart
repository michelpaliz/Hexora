import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class VatSummaryApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  VatSummaryApiException({
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
    return 'VAT Summary API ($statusCode) $method $url: $message$body';
  }
}

class VatSummaryApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/tax/iva/summary'
      : '${ApiConstants.baseUrl}/api/tax/iva/summary';
  final String _apiRoot = ApiConstants.baseUrl.endsWith('/api')
      ? ApiConstants.baseUrl
      : '${ApiConstants.baseUrl}/api';

  Uri _u({String? groupId, String? from, String? to, String? currency}) {
    final params = <String, String>{};
    if (groupId != null && groupId.trim().isNotEmpty) {
      params['groupId'] = groupId.trim();
    }
    if (from != null && from.trim().isNotEmpty) {
      params['from'] = from.trim();
    }
    if (to != null && to.trim().isNotEmpty) {
      params['to'] = to.trim();
    }
    final curr = (currency ?? '').trim().toUpperCase();
    if (curr.isNotEmpty) {
      params['currency'] = curr;
    }
    return Uri.parse(_base).replace(queryParameters: params);
  }

  Map<String, String> _headers() => <String, String>{
        'Content-Type': 'application/json',
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

    final ex = VatSummaryApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    final isKnownEurOnly = r.statusCode == 400 &&
        msg.toLowerCase().contains('only eur currency is supported');
    if (kDebugMode && !isKnownEurOnly) {
      debugPrint(ex.toString());
    }
    throw ex;
  }

  Future<Map<String, dynamic>> getSummary({
    String? groupId,
    String? from,
    String? to,
    String currency = 'EUR',
  }) async {
    final uri = _u(
      groupId: groupId,
      from: from,
      to: to,
      currency: currency,
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getQuarterSummary({
    String? groupId,
    required int year,
    required int quarter,
  }) async {
    final safeQuarter = quarter.clamp(1, 4);
    final params = <String, String>{
      'year': year.toString(),
      'quarter': 'T$safeQuarter',
      if ((groupId ?? '').trim().isNotEmpty) 'groupId': groupId!.trim(),
    };
    final uri = Uri.parse('$_apiRoot/vat-audit/summary')
        .replace(queryParameters: params);
    var r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    var resolvedUri = uri;
    if (r.statusCode == 404) {
      resolvedUri =
          Uri.parse('$_apiRoot/vat/summary').replace(queryParameters: params);
      r = await AuthenticatedHttpClient.get(resolvedUri, headers: _headers());
    }
    return _decode<Map<String, dynamic>>(
      r,
      url: resolvedUri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }
}
