import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';

class RecurrenceRuleApiClient {
  // final String _baseUrl = 'http://192.168.1.16:3000/api/recurrence-rules';

  final String _baseUrl = '${ApiConstants.baseUrl}/recurrence-rules';

  Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  /// Create a new recurrence rule
  Future<LegacyRecurrenceRule> createRule(LegacyRecurrenceRule rule) async {
    final response = await AuthenticatedHttpClient.post(
      Uri.parse(_baseUrl),
      headers: _authHeaders(),
      body: jsonEncode(rule.toJson()),
    );

    devtools.log('🔁 POST /recurrence-rules → ${response.statusCode}');
    devtools.log('ðŸ“¦ Payload: ${rule.toJson()}');

    if (response.statusCode == 201) {
      return LegacyRecurrenceRule.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create recurrence rule: ${response.body}');
    }
  }

  /// Get all recurrence rules (optional, useful for admin/debug)
  Future<List<LegacyRecurrenceRule>> getAllRules() async {
    final response = await AuthenticatedHttpClient.get(
      Uri.parse(_baseUrl),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => LegacyRecurrenceRule.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch recurrence rules');
    }
  }

  /// Get a rule by ID (if needed)
  Future<LegacyRecurrenceRule> getRuleById(String id) async {
    final url = '$_baseUrl/$id';
    final response = await AuthenticatedHttpClient.get(
      Uri.parse(url),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return LegacyRecurrenceRule.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to get recurrence rule: ${response.reasonPhrase}',
      );
    }
  }

  /// Bulk fetch recurrence rules by their IDs
  Future<List<LegacyRecurrenceRule>> getRulesByIds(List<String> ids) async {
    final url = '$_baseUrl/byIds'; // Backend should have this route
    final response = await AuthenticatedHttpClient.post(
      Uri.parse(url),
      headers: _authHeaders(),
      body: jsonEncode({'ids': ids}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LegacyRecurrenceRule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch rules by IDs: ${response.body}');
    }
  }
}
