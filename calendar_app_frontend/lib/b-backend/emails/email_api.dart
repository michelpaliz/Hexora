import 'dart:convert';

import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class EmailApi {
  final String _base = '${ApiConstants.baseUrl}/api/emails';

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await TokenService.loadToken()}',
      };

  Uri _u([String path = '']) => Uri.parse('$_base$path');

  T _decode<T>(http.Response r, T Function(dynamic) map) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }

    if (ok) {
      return map(body);
    }

    String message = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw Exception(message);
  }

  Future<Map<String, dynamic>> getStatus() async {
    final r = await http.get(_u('/status'), headers: await _headers());
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      return <String, dynamic>{};
    });
  }

  Future<List<Map<String, dynamic>>> getLogs({
    required String invoiceId,
    required String groupId,
  }) async {
    final uri = _u('/logs?invoiceId=$invoiceId&groupId=$groupId');
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(r, (j) {
      if (j is! List) return <Map<String, dynamic>>[];
      return j.whereType<Map<String, dynamic>>().toList();
    });
  }

  Future<Map<String, dynamic>> previewTemplate(
      Map<String, dynamic> payload) async {
    final r = await http.post(
      _u('/templates/preview'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      return <String, dynamic>{};
    });
  }

  Future<Map<String, dynamic>> sendInvoice(Map<String, dynamic> payload) async {
    final r = await http.post(
      _u('/send-invoice'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      return <String, dynamic>{};
    });
  }

  Future<void> resend(String emailLogId) async {
    final r = await http.post(
      _u('/resend/$emailLogId'),
      headers: await _headers(),
      body: jsonEncode({}),
    );
    _decode<void>(r, (_) => null);
  }
}
