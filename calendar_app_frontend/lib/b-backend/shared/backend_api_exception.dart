import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendApiException implements Exception {
  final int statusCode;
  final String? code;
  final String message;
  final String? rawBody;

  const BackendApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.rawBody,
  });

  factory BackendApiException.fromResponse(
    http.Response response, {
    String fallbackMessage = 'Request failed',
  }) {
    final body = response.body;
    String? code;
    String message = fallbackMessage;

    if (body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final rawCode = decoded['code'] ?? decoded['errorCode'];
          code = rawCode?.toString().trim();
          final rawMessage =
              decoded['message'] ?? decoded['error'] ?? decoded['detail'];
          final parsedMessage = rawMessage?.toString().trim() ?? '';
          if (parsedMessage.isNotEmpty) {
            message = parsedMessage;
          }
        } else if (decoded is String && decoded.trim().isNotEmpty) {
          message = decoded.trim();
        }
      } catch (_) {
        if (body.trim().isNotEmpty) {
          message = body.trim();
        }
      }
    } else if ((response.reasonPhrase ?? '').trim().isNotEmpty) {
      message = response.reasonPhrase!.trim();
    }

    return BackendApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
      rawBody: body.isEmpty ? null : body,
    );
  }

  @override
  String toString() {
    final c = (code ?? '').trim();
    if (c.isNotEmpty) {
      return 'BackendApiException($statusCode/$c): $message';
    }
    return 'BackendApiException($statusCode): $message';
  }
}
