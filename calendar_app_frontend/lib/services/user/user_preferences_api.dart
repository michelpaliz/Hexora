import 'dart:convert';

import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';

class UserPreferencesApi {
  static Uri get _uri =>
      Uri.parse('${ApiConstants.baseUrl}/users/me/preferences');

  static Future<Map<String, dynamic>> load() async {
    final response = await AuthenticatedHttpClient.get(_uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load user preferences (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
  }

  static Future<void> update(Map<String, dynamic> changes) async {
    final response = await AuthenticatedHttpClient.patch(
      _uri,
      body: jsonEncode(changes),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to save user preferences (${response.statusCode})');
    }
  }
}
