import 'dart:convert';

import 'package:hexora/a-models/group_model/private_document/private_document.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class PrivateDocumentsApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  PrivateDocumentsApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'Exception: $message';
}

class PrivateDocumentsApi {
  static const maxUploadBytes = 20 * 1024 * 1024;

  final String _base = '${ApiConstants.baseUrl}/groups';

  Uri _u(String groupId, [String path = '']) =>
      Uri.parse('$_base/${groupId.trim()}/private-documents$path');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

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
      throw Exception('Unexpected private document payload');
    }
    throw PrivateDocumentsApiException(
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
      final raw = body is List
          ? body
          : body is Map && body['items'] is List
              ? body['items'] as List
              : body is Map && body['documents'] is List
                  ? body['documents'] as List
                  : null;
      if (raw != null) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
      throw Exception('Unexpected private document list payload');
    }
    throw PrivateDocumentsApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<String> _requireAuthToken() async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = headers['Authorization'] ?? '';
    if (auth.trim().isEmpty) {
      throw PrivateDocumentsApiException(
        statusCode: 401,
        message: 'Not authenticated',
      );
    }
    return auth;
  }

  Future<List<PrivateDocument>> list({
    required String groupId,
    String? category,
    String? status,
  }) async {
    final query = <String, String>{
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };
    final uri =
        query.isEmpty ? _u(groupId) : _u(groupId).replace(queryParameters: query);
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decodeList(r).map(PrivateDocument.fromJson).toList(growable: false);
  }

  Future<PrivateDocument> getById({
    required String groupId,
    required String documentId,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u(groupId, '/${documentId.trim()}'),
      headers: _headers(),
    );
    return PrivateDocument.fromJson(_decodeMap(r));
  }

  /// Backend issues a private Azure download URL valid for five minutes.
  Future<String> getFileDownloadUrl({
    required String groupId,
    required String documentId,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u(groupId, '/${documentId.trim()}/file'),
      headers: _headers(),
    );
    final body = _decodeMap(r);
    final url = (body['url'] ?? body['downloadUrl'] ?? body['fileUrl'] ?? '')
        .toString()
        .trim();
    if (url.isEmpty) {
      throw Exception('Missing download URL in server response');
    }
    return url;
  }

  Future<PrivateDocument> upload({
    required String groupId,
    required List<int> bytes,
    required String fileName,
    required String category,
    String status = PrivateDocumentReviewStatus.pendingReview,
    String? title,
    DateTime? expiryDate,
    String? notes,
    List<String>? tags,
    List<String>? counterparties,
  }) async {
    final auth = await _requireAuthToken();
    final req = http.MultipartRequest('POST', _u(groupId));
    req.headers['Authorization'] = auth;
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    req.fields['category'] = category;
    req.fields['status'] = status;
    if ((title ?? '').trim().isNotEmpty) req.fields['title'] = title!.trim();
    if (expiryDate != null) {
      req.fields['expiryDate'] = expiryDate.toIso8601String();
    }
    if ((notes ?? '').trim().isNotEmpty) req.fields['notes'] = notes!.trim();
    if (tags != null && tags.isNotEmpty) {
      req.fields['tags'] = jsonEncode(tags);
    }
    if (counterparties != null && counterparties.isNotEmpty) {
      req.fields['counterparties'] = jsonEncode(counterparties);
    }
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return PrivateDocument.fromJson(_decodeMap(response));
  }

  Future<PrivateDocument> update({
    required String groupId,
    required String documentId,
    String? title,
    String? category,
    String? status,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? notes,
    List<String>? tags,
    List<String>? counterparties,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (clearExpiryDate) 'expiryDate': null,
      if (!clearExpiryDate && expiryDate != null)
        'expiryDate': expiryDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (tags != null) 'tags': tags,
      if (counterparties != null) 'counterparties': counterparties,
    };
    final r = await AuthenticatedHttpClient.patch(
      _u(groupId, '/${documentId.trim()}'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return PrivateDocument.fromJson(_decodeMap(r));
  }

  Future<void> remove({
    required String groupId,
    required String documentId,
  }) async {
    final r = await AuthenticatedHttpClient.delete(
      _u(groupId, '/${documentId.trim()}'),
      headers: _headers(),
    );
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) return;
    final body = _tryDecodeBody(r.body);
    throw PrivateDocumentsApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }
}
