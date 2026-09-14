import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class JsonApiErrorContext {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;
  final Map<String, String> responseHeaders;

  const JsonApiErrorContext({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.method,
    required this.responseBody,
    required this.responseHeaders,
  });
}

T decodeJsonResponse<T>(
  http.Response response, {
  required Uri url,
  required String method,
  required T Function(dynamic json) map,
  required Object Function(JsonApiErrorContext context) createException,
  List<String> errorMessageKeys = const ['message', 'error'],
  bool Function(JsonApiErrorContext context)? shouldLogError,
}) {
  final ok = response.statusCode >= 200 && response.statusCode < 300;
  dynamic body;
  if (response.body.isNotEmpty) {
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }
  }

  if (ok) return map(body);

  String message = response.reasonPhrase ?? 'Request failed';
  if (body is Map) {
    for (final key in errorMessageKeys) {
      if (body[key] != null) {
        message = body[key].toString();
        break;
      }
    }
  } else if (body is String && body.trim().isNotEmpty) {
    message = body.trim();
  }

  final context = JsonApiErrorContext(
    statusCode: response.statusCode,
    message: message,
    url: url,
    method: method,
    responseBody: response.body.isEmpty ? null : response.body,
    responseHeaders: response.headers,
  );
  final exception = createException(context);
  if (kDebugMode && (shouldLogError?.call(context) ?? true)) {
    debugPrint(exception.toString());
  }
  throw exception;
}
