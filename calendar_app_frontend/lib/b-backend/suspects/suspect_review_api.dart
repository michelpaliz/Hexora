import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class SuspectReviewApiException implements Exception {
  final String apiName;
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  SuspectReviewApiException({
    required this.apiName,
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
    return '$apiName ($statusCode) $method $url: $message$body';
  }
}

class SuspectReviewResult {
  final Map<String, dynamic> data;
  final Uri requestUrl;
  final int statusCode;

  const SuspectReviewResult({
    required this.data,
    required this.requestUrl,
    required this.statusCode,
  });
}

abstract class SuspectReviewApi<R extends SuspectReviewResult> {
  String get resourceName;
  String get apiName;
  String get totalScannedKey;
  bool get clearNotesWhenUnreviewed => false;

  SuspectReviewApiException createException({
    required int statusCode,
    required String message,
    required Uri url,
    required String method,
    String? responseBody,
  });

  R createResult({
    required Map<String, dynamic> data,
    required Uri requestUrl,
    required int statusCode,
  });

  String get _base {
    final base = ApiConstants.baseUrl;
    return base.endsWith('/api')
        ? '$base/$resourceName/suspects'
        : '$base/api/$resourceName/suspects';
  }

  String _reviewUrl(String documentId) {
    final base = ApiConstants.baseUrl;
    return base.endsWith('/api')
        ? '$base/$resourceName/$documentId/suspicion-review'
        : '$base/api/$resourceName/$documentId/suspicion-review';
  }

  Map<String, String> _headers() => const {'Content-Type': 'application/json'};

  Map<String, dynamic> _decodeBody(
    http.Response response, {
    required Uri url,
    required String method,
  }) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (error) {
        if (kDebugMode) debugPrint('[$apiName] JSON parse error: $error');
        body = response.body;
      }
    }

    if (ok && body is Map) return Map<String, dynamic>.from(body);

    String message = response.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }

    final exception = createException(
      statusCode: response.statusCode,
      message: message,
      url: url,
      method: method,
      responseBody: response.body.isEmpty ? null : response.body,
    );
    if (kDebugMode) debugPrint('[$apiName] ERROR: $exception');
    throw exception;
  }

  Future<R> getSuspects({
    String? groupId,
    String? from,
    String? to,
    String? currency,
    double? tolerance,
    String? reviewStatus,
  }) async {
    final params = <String, String>{
      if (groupId?.trim().isNotEmpty ?? false) 'groupId': groupId!.trim(),
      if (from?.trim().isNotEmpty ?? false) 'from': from!.trim(),
      if (to?.trim().isNotEmpty ?? false) 'to': to!.trim(),
      if (currency?.trim().isNotEmpty ?? false)
        'currency': currency!.trim().toUpperCase(),
      if (tolerance != null) 'tolerance': tolerance.toString(),
      if (reviewStatus?.trim().isNotEmpty ?? false)
        'reviewStatus': reviewStatus!.trim(),
    };
    final uri = Uri.parse(_base).replace(queryParameters: params);

    if (kDebugMode) debugPrint('[$apiName] GET $uri');
    final response =
        await AuthenticatedHttpClient.get(uri, headers: _headers());
    if (kDebugMode) {
      debugPrint(
        '[$apiName] response status=${response.statusCode} '
        'body=${response.body.length > 500 ? "${response.body.substring(0, 500)}..." : response.body}',
      );
    }

    final data = _decodeBody(response, url: uri, method: 'GET');
    if (kDebugMode) {
      debugPrint(
        '[$apiName] parsed -> '
        'ok=${data["ok"]} '
        '$totalScannedKey=${data[totalScannedKey]} '
        'suspectCount=${data["suspectCount"]} '
        'suspects.length=${(data["suspects"] as List?)?.length ?? "null"}',
      );
    }

    return createResult(
      data: data,
      requestUrl: uri,
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> patchReview(
    String documentId, {
    required String status,
    String? notes,
  }) async {
    final uri = Uri.parse(_reviewUrl(documentId));
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    } else if (clearNotesWhenUnreviewed && status == 'unreviewed') {
      body['notes'] = null;
    }

    if (kDebugMode) {
      debugPrint('[$apiName] PATCH $uri body=${jsonEncode(body)}');
    }
    final response = await AuthenticatedHttpClient.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (kDebugMode) {
      debugPrint('[$apiName] PATCH response status=${response.statusCode}');
    }

    return _decodeBody(response, url: uri, method: 'PATCH');
  }
}
