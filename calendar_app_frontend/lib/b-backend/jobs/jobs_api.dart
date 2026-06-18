import 'dart:convert';

import 'package:hexora/a-models/jobs/background_job.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class JobsApiException implements Exception {
  const JobsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'Exception: $message';
}

class JobsApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/jobs'
      : '${ApiConstants.baseUrl}/api/jobs';

  Uri _u([String path = '', Map<String, String>? query]) {
    final uri = Uri.parse('$_base$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  void _ensureOk(http.Response response, {String fallback = 'Request failed'}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = _decodeBody(response);
    var message = fallback;
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw JobsApiException(message, statusCode: response.statusCode);
  }

  Future<List<BackgroundJob>> listJobs({
    String? status,
    String? type,
    int limit = 20,
    int skip = 0,
  }) async {
    final normalizedType = type?.trim() ?? '';
    final response = await AuthenticatedHttpClient.get(
      _u('', {
        if (status != null && status.isNotEmpty) 'status': status,
        if (normalizedType.isNotEmpty) 'type': normalizedType,
        'limit': '$limit',
        if (skip > 0) 'skip': '$skip',
      }),
    );
    if (response.statusCode == 400 && normalizedType.isNotEmpty) {
      final fallback = await listJobs(
        status: status,
        limit: limit,
        skip: skip,
      );
      return fallback
          .where(
              (job) => job.type.toUpperCase() == normalizedType.toUpperCase())
          .toList(growable: false);
    }
    _ensureOk(response, fallback: 'Could not load jobs.');
    final body = _decodeBody(response);
    final raw = body is List
        ? body
        : body is Map
            ? (body['items'] ?? body['jobs'] ?? body['data'] ?? body['results'])
            : null;
    if (raw is! List) return const <BackgroundJob>[];
    return raw
        .whereType<Map>()
        .map((entry) => BackgroundJob.fromJson(
              Map<String, dynamic>.from(entry),
            ))
        .toList(growable: false);
  }

  Future<BackgroundJob> getJob(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) throw const JobsApiException('job id is required');
    final response = await AuthenticatedHttpClient.get(_u('/$trimmed'));
    _ensureOk(response, fallback: 'Could not load job.');
    final body = _decodeBody(response);
    final raw = body is Map && body['job'] is Map ? body['job'] : body;
    if (raw is! Map) {
      throw const JobsApiException('Invalid job response.');
    }
    return BackgroundJob.fromJson(Map<String, dynamic>.from(raw));
  }
}
