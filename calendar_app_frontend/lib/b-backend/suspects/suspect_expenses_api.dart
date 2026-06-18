import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class SuspectExpensesApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  SuspectExpensesApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.method,
    this.responseBody,
  });

  @override
  String toString() {
    final body = (responseBody == null || responseBody!.trim().isEmpty)
        ? ''
        : '\nbody: ${responseBody!.trim()}';
    return 'SuspectExpensesApi ($statusCode) $method $url: $message$body';
  }
}

/// Result wrapper so callers can inspect debug metadata without re-parsing.
class SuspectExpensesResult {
  final Map<String, dynamic> data;
  final Uri requestUrl;
  final int statusCode;

  const SuspectExpensesResult({
    required this.data,
    required this.requestUrl,
    required this.statusCode,
  });
}

class SuspectExpensesApi {
  String get _base {
    final b = ApiConstants.baseUrl;
    return b.endsWith('/api')
        ? '$b/expenses/suspects'
        : '$b/api/expenses/suspects';
  }

  String _reviewUrl(String expenseId) {
    final b = ApiConstants.baseUrl;
    return b.endsWith('/api')
        ? '$b/expenses/$expenseId/suspicion-review'
        : '$b/api/expenses/$expenseId/suspicion-review';
  }

  Map<String, String> _headers() => {'Content-Type': 'application/json'};

  Map<String, dynamic> _decodeBody(
    http.Response r, {
    required Uri url,
    required String method,
  }) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SuspectExpensesApi] JSON parse error: $e');
        }
        body = r.body;
      }
    }

    if (ok && body is Map) return Map<String, dynamic>.from(body);

    String msg = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      msg = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      msg = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body.trim();
    }

    final ex = SuspectExpensesApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    if (kDebugMode) debugPrint('[SuspectExpensesApi] ERROR: $ex');
    throw ex;
  }

  /// GET /api/expenses/suspects
  ///
  /// Returns a [SuspectExpensesResult] that includes the request URL and
  /// HTTP status alongside the decoded body — useful for the debug panel.
  Future<SuspectExpensesResult> getSuspects({
    String? groupId,
    String? from,
    String? to,
    String? currency,
    double? tolerance,
    String? reviewStatus,
  }) async {
    final params = <String, String>{};
    if (groupId != null && groupId.trim().isNotEmpty) {
      params['groupId'] = groupId.trim();
    }
    if (from != null && from.trim().isNotEmpty) params['from'] = from.trim();
    if (to != null && to.trim().isNotEmpty) params['to'] = to.trim();
    if (currency != null && currency.trim().isNotEmpty) {
      params['currency'] = currency.trim().toUpperCase();
    }
    if (tolerance != null) params['tolerance'] = tolerance.toString();
    // Only send reviewStatus when it is non-null / non-empty (omit for "All")
    if (reviewStatus != null && reviewStatus.trim().isNotEmpty) {
      params['reviewStatus'] = reviewStatus.trim();
    }

    final uri = Uri.parse(_base).replace(queryParameters: params);

    if (kDebugMode) {
      debugPrint('[SuspectExpensesApi] GET $uri');
    }

    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());

    if (kDebugMode) {
      debugPrint(
        '[SuspectExpensesApi] response status=${r.statusCode} '
        'body=${r.body.length > 500 ? "${r.body.substring(0, 500)}…" : r.body}',
      );
    }

    final data = _decodeBody(r, url: uri, method: 'GET');

    if (kDebugMode) {
      debugPrint(
        '[SuspectExpensesApi] parsed → '
        'ok=${data["ok"]} '
        'totalExpensesScanned=${data["totalExpensesScanned"]} '
        'suspectCount=${data["suspectCount"]} '
        'suspects.length=${(data["suspects"] as List?)?.length ?? "null"}',
      );
    }

    return SuspectExpensesResult(
      data: data,
      requestUrl: uri,
      statusCode: r.statusCode,
    );
  }

  /// PATCH /api/expenses/:id/suspicion-review
  Future<Map<String, dynamic>> patchReview(
    String expenseId, {
    required String status,
    String? notes,
  }) async {
    final uri = Uri.parse(_reviewUrl(expenseId));
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    } else if (status == 'unreviewed') {
      body['notes'] = null;
    }

    if (kDebugMode) {
      debugPrint('[SuspectExpensesApi] PATCH $uri body=${jsonEncode(body)}');
    }

    final r = await AuthenticatedHttpClient.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (kDebugMode) {
      debugPrint('[SuspectExpensesApi] PATCH response status=${r.statusCode}');
    }

    return _decodeBody(r, url: uri, method: 'PATCH');
  }
}
