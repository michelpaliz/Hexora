import 'dart:convert';

import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';

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
    throw Exception(message);
  }

  Future<Map<String, dynamic>> board(String groupId) async =>
      _decode(await AuthenticatedHttpClient.get(_uri(groupId)));

  Future<Map<String, dynamic>> create(
    String groupId,
    Map<String, dynamic> payload,
  ) async =>
      _decode(await AuthenticatedHttpClient.post(
        _uri(groupId),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ));

  Future<Map<String, dynamic>> update(
    String groupId,
    String noteId,
    Map<String, dynamic> patch,
  ) async =>
      _decode(await AuthenticatedHttpClient.patch(
        _uri(groupId, '/$noteId'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(patch),
      ));

  Future<Map<String, dynamic>> updateLimits(
    String groupId,
    Map<String, int?> limits,
  ) async =>
      _decode(await AuthenticatedHttpClient.patch(
        _uri(groupId, '/board'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'columnLimits': limits}),
      ));

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
