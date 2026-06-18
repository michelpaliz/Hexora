import 'dart:convert';

import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class DownloadsApiException implements Exception {
  DownloadsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'Exception: $message';
}

class DownloadsApi {
  final String _base = '${ApiConstants.baseUrl}/downloads';

  Uri _u([String path = '', Map<String, String>? query]) {
    final raw = '$_base$path';
    final uri = Uri.parse(raw);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        ...query,
      },
    );
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
    String message = fallback;
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw DownloadsApiException(message, statusCode: response.statusCode);
  }

  Future<List<DownloadJob>> listJobs({
    required String groupId,
    String? status,
    String? jobType,
    bool mine = true,
    int limit = 50,
    String? from,
    String? to,
  }) async {
    final response = await AuthenticatedHttpClient.get(
      _u('', {
        'groupId': groupId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (jobType != null && jobType.isNotEmpty) 'jobType': jobType,
        if (mine) 'mine': 'true',
        'limit': '$limit',
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      }),
    );
    _ensureOk(response, fallback: 'Could not load downloads.');
    final body = _decodeBody(response);
    final raw = body is Map ? body['jobs'] : null;
    if (raw is! List) return const <DownloadJob>[];
    return raw
        .whereType<Map>()
        .map((e) => DownloadJob.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<DownloadJob> getJob(String id) async {
    final response = await AuthenticatedHttpClient.get(_u('/$id'));
    _ensureOk(response, fallback: 'Could not load download details.');
    final body = _decodeBody(response);
    if (body is! Map || body['job'] is! Map) {
      throw DownloadsApiException('Invalid download job response.');
    }
    return DownloadJob.fromJson(
      Map<String, dynamic>.from(body['job'] as Map),
    );
  }

  Future<DownloadJob> createJob({
    required String groupId,
    required String jobType,
    required String title,
    required String description,
    required Map<String, dynamic> params,
  }) async {
    final response = await AuthenticatedHttpClient.post(
      _u(),
      body: jsonEncode({
        'groupId': groupId,
        'jobType': jobType,
        'title': title,
        'description': description,
        'params': params,
      }),
    );
    _ensureOk(response, fallback: 'Could not create download job.');
    final body = _decodeBody(response);
    if (body is! Map || body['job'] is! Map) {
      throw DownloadsApiException('Invalid download job response.');
    }
    return DownloadJob.fromJson(
      Map<String, dynamic>.from(body['job'] as Map),
    );
  }

  Future<http.Response> downloadFile(DownloadJob job) async {
    final url = job.downloadUrl.trim().isNotEmpty
        ? job.downloadUrl.trim()
        : '/api/downloads/${job.id}/file';
    final response = await AuthenticatedHttpClient.get(
      Uri.parse(_resolveUrl(url)),
      headers: const <String, String>{
        'Content-Type': 'application/octet-stream',
      },
    );
    _ensureOk(response, fallback: 'Could not download file.');
    return response;
  }

  String _resolveUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (ApiConstants.baseUrl.startsWith('http://') ||
        ApiConstants.baseUrl.startsWith('https://')) {
      final base = ApiConstants.baseUrl.endsWith('/')
          ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
          : ApiConstants.baseUrl;
      if (raw.startsWith('/api')) {
        final uri = Uri.parse(base);
        return '${uri.scheme}://${uri.authority}$raw';
      }
      return '$base${raw.startsWith('/') ? '' : '/'}$raw';
    }
    return raw;
  }
}
