import 'dart:convert';

import 'package:hexora/data/auth/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/data/config/api_constants.dart';
import 'package:hexora/models/weather/work_condition_result.dart';

class WorkConditionsApi {
  Uri _uri(String groupId, DateTime from, DateTime to) {
    final raw = ApiConstants.baseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    final base = raw.endsWith('/api') ? raw : '$raw/api';
    return Uri.parse('$base/weather/work-conditions/$groupId').replace(
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
  }

  Future<WorkConditionResult> today(String groupId) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1));
    final response = await AuthenticatedHttpClient.get(
      _uri(groupId, from, to),
      headers: const {'Accept': 'application/json'},
    );
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map ? body['error']?.toString() : null;
      throw Exception(message ?? 'Unable to analyze work conditions');
    }
    if (body is! Map) throw Exception('Invalid work-condition response');
    return WorkConditionResult.fromJson(body.cast<String, dynamic>());
  }
}
