import 'dart:convert';

import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';
import 'package:http/http.dart' as http;

class QuickNotesApi {
  Uri _uri(String groupId, [String path = '']) =>
      Uri.parse('${ApiConstants.baseUrl}/groups/$groupId/quick-notes$path');

  Map<String, dynamic> _decode(dynamic response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    var message = 'Request failed';
    try {
      final body = jsonDecode(response.body);
      message = body['message']?.toString() ?? message;
    } catch (_) {}
    throw BackendApiException(
      statusCode: response.statusCode,
      message: message,
      rawBody: response.body.isEmpty ? null : response.body,
    );
  }

  Future<http.Response> _withGatewayRetry(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    // The notes service can briefly return a gateway error while the API
    // instance wakes up. Give it a little more time before the board switches
    // to the unavailable state, while keeping the retry bounded.
    for (var attempt = 0;
        attempt < 4 && const {502, 503, 504}.contains(response.statusCode);
        attempt++) {
      await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
      response = await request();
    }
    return response;
  }

  Future<Map<String, dynamic>> board(String groupId) async => _decode(
        await _withGatewayRetry(
            () => AuthenticatedHttpClient.get(_uri(groupId))),
      );

  Future<Map<String, dynamic>> create(
    String groupId,
    Map<String, dynamic> payload,
  ) async =>
      _decode(await _withGatewayRetry(() => AuthenticatedHttpClient.post(
            _uri(groupId),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )));

  Future<Map<String, dynamic>> update(
    String groupId,
    String noteId,
    Map<String, dynamic> patch,
  ) async =>
      _decode(await _withGatewayRetry(() => AuthenticatedHttpClient.patch(
            _uri(groupId, '/$noteId'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(patch),
          )));

  Future<Map<String, dynamic>> updateLimits(
    String groupId,
    Map<String, int?> limits,
  ) async =>
      _decode(await _withGatewayRetry(() => AuthenticatedHttpClient.patch(
            _uri(groupId, '/board'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'columnLimits': limits}),
          )));

  Future<void> delete(
    String groupId,
    String noteId, {
    required String reason,
  }) async {
    final response = await AuthenticatedHttpClient.delete(
      _uri(groupId, '/$noteId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response);
    }
  }
}
