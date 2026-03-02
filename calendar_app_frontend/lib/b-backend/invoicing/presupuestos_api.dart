import 'dart:convert';

import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class PresupuestosApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  PresupuestosApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'Exception: $message';
}

class PresupuestosApi {
  final String _base = '${ApiConstants.baseUrl}/presupuestos';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Uri _u([String path = '']) => Uri.parse('$_base$path');

  Uri buildListByGroupUri(
    String groupId, {
    String? clientId,
    String? sortBy,
    String? sortDir,
  }) {
    final query = <String, String>{
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
      if (sortBy != null && sortBy.trim().isNotEmpty) 'sortBy': sortBy.trim(),
      if (sortDir != null && sortDir.trim().isNotEmpty)
        'sortDir': sortDir.trim(),
    };
    return query.isEmpty
        ? _u('/group/${groupId.trim()}')
        : _u('/group/${groupId.trim()}?${Uri(queryParameters: query).query}');
  }

  dynamic _tryDecodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String _resolveErrorMessage(http.Response r, dynamic body) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }
    return r.reasonPhrase ?? 'Request failed';
  }

  String? _resolveErrorCode(dynamic body) {
    if (body is Map && body['code'] != null) {
      final code = body['code'].toString().trim();
      return code.isEmpty ? null : code;
    }
    return null;
  }

  Map<String, dynamic>? _resolveErrorDetails(dynamic body) {
    if (body is Map && body['details'] is Map) {
      return Map<String, dynamic>.from(body['details'] as Map);
    }
    return null;
  }

  Map<String, dynamic> _decodeMap(http.Response r) {
    final body = _tryDecodeBody(r.body);
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) {
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected presupuesto payload');
    }
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  List<Map<String, dynamic>> _decodeList(http.Response r) {
    final body = _tryDecodeBody(r.body);
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
      if (body is Map && body['items'] is List) {
        return (body['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
      throw Exception('Unexpected presupuesto list payload');
    }
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> createDraft({
    required String groupId,
    String? clientId,
    String? clientName,
    List<Map<String, dynamic>>? lines,
    List<Map<String, dynamic>>? blocks,
  }) async {
    final payload = <String, dynamic>{
      'groupId': groupId,
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
      if (clientName != null && clientName.trim().isNotEmpty)
        'clientName': clientName.trim(),
      if (lines != null && lines.isNotEmpty) 'lines': lines,
      if (blocks != null && blocks.isNotEmpty) 'blocks': blocks,
    };
    final r = await AuthenticatedHttpClient.post(
      _u(),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> issue(String id) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/issue'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<void> remove(String id) async {
    final r = await AuthenticatedHttpClient.delete(
      _u('/$id'),
      headers: _headers(),
    );
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) return;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> convertToInvoice(String id) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/convert-to-invoice'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<List<Map<String, dynamic>>> listByGroup({
    required String groupId,
    String? clientId,
    String? sortBy,
    String? sortDir,
  }) async {
    final uri = buildListByGroupUri(
      groupId,
      clientId: clientId,
      sortBy: sortBy,
      sortDir: sortDir,
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decodeList(r);
  }

  Future<http.Response> previewPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf/preview'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to preview presupuesto PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> downloadPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to download presupuesto PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> downloadAllPdfsZip({
    required String groupId,
  }) async {
    final uri = Uri.parse('$_base/pdf/all').replace(
      queryParameters: {'groupId': groupId},
    );
    final headers = _headers();
    headers['Accept'] = 'application/zip';
    final r = await AuthenticatedHttpClient.get(uri, headers: headers);
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to download presupuestos ZIP (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final r =
        await AuthenticatedHttpClient.get(_u('/$id'), headers: _headers());
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getImportJsonPromptTemplate(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/import-json/prompt-template'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> importJson(String id, dynamic payload) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/import-json'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> extractImageOpenAi({
    required String id,
    required List<int> bytes,
    required String fileName,
    String fieldName = 'image',
  }) async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = headers['Authorization'] ?? '';
    if (auth.trim().isEmpty) {
      throw PresupuestosApiException(
          statusCode: 401, message: 'Not authenticated');
    }

    final req = http.MultipartRequest('POST', _u('/$id/extract-image'));
    req.headers['Authorization'] = auth;
    req.fields['method'] = 'openai';
    req.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );

    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }

  Future<String> _requireAuthToken({
    required String path,
    required String method,
  }) async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = headers['Authorization'] ?? '';
    if (auth.trim().isEmpty) {
      throw PresupuestosApiException(
          statusCode: 401, message: 'Not authenticated');
    }
    return auth;
  }

  Future<Map<String, dynamic>> _postMultipartImage({
    required String path,
    required List<int> bytes,
    required String fileName,
    String fieldName = 'image',
  }) async {
    final auth = await _requireAuthToken(path: path, method: 'POST');
    final req = http.MultipartRequest('POST', _u(path));
    req.headers['Authorization'] = auth;
    req.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> extractLinesOcr({
    required String id,
    required List<int> bytes,
    required String fileName,
    String fieldName = 'image',
    bool preview = false,
  }) async {
    final path = preview ? '/$id/lines/ocr-preview' : '/$id/lines/ocr';
    return _postMultipartImage(
      path: path,
      bytes: bytes,
      fileName: fileName,
      fieldName: fieldName,
    );
  }

  Future<Map<String, dynamic>> importLinesMultipart({
    required String id,
    required Map<String, dynamic> payload,
    String fieldName = 'file',
    String fileName = 'lines.json',
  }) async {
    final path = '/$id/lines/import';
    final auth = await _requireAuthToken(path: path, method: 'POST');
    final req = http.MultipartRequest('POST', _u(path));
    req.headers['Authorization'] = auth;
    req.files.add(
      http.MultipartFile.fromString(
        fieldName,
        jsonEncode(payload),
        filename: fileName,
      ),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }
}
