import 'dart:convert';

import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class ReceiptsApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final String? existingReceiptId;
  final Receipt? receipt;
  final String? responseBody;
  final Map<String, String>? responseHeaders;
  final Uri url;
  final String method;

  ReceiptsApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.existingReceiptId,
    this.receipt,
    required this.url,
    required this.method,
    required this.responseBody,
    required this.responseHeaders,
  });

  @override
  String toString() => 'Exception: $message';
}

class UnnumberedReceiptDraftLookup {
  const UnnumberedReceiptDraftLookup({
    required this.exists,
    this.existingReceiptId,
    this.receipt,
  });

  final bool exists;
  final String? existingReceiptId;
  final Receipt? receipt;

  factory UnnumberedReceiptDraftLookup.fromJson(Map<String, dynamic> json) {
    return UnnumberedReceiptDraftLookup(
      exists: json['exists'] == true,
      existingReceiptId: json['existingReceiptId']?.toString(),
      receipt: json['receipt'] is Map
          ? Receipt.fromJson(
              Map<String, dynamic>.from(json['receipt'] as Map),
            )
          : null,
    );
  }
}

class ReceiptsApi {
  final String _base = '${ApiConstants.baseUrl}/receipts';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
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

    if (ok) return map(body);

    String message = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }

    throw ReceiptsApiException(
      statusCode: r.statusCode,
      message: message,
      code: body is Map ? body['code']?.toString() : null,
      existingReceiptId:
          body is Map ? body['existingReceiptId']?.toString() : null,
      receipt: body is Map && body['receipt'] is Map
          ? Receipt.fromJson(Map<String, dynamic>.from(body['receipt'] as Map))
          : null,
      url: r.request?.url ?? _u(),
      method: r.request?.method ?? 'REQUEST',
      responseBody: r.body.isEmpty ? null : r.body,
      responseHeaders: r.headers,
    );
  }

  Future<Receipt> create(Receipt receipt) async {
    final r = await AuthenticatedHttpClient.post(
      _u(),
      headers: _headers(),
      body: jsonEncode(receipt.toCreatePayload()),
    );
    return _decode<Receipt>(r, (j) {
      if (j is Map<String, dynamic>) return Receipt.fromJson(j);
      throw Exception('Unexpected receipt payload');
    });
  }

  Future<List<Receipt>> list({
    required String groupId,
    String? status,
  }) async {
    final params = <String, String>{'groupId': groupId};
    if (status != null && status.trim().isNotEmpty) params['status'] = status;
    final uri = _u().replace(queryParameters: params);
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<List<Receipt>>(r, (j) {
      if (j is! List) throw Exception('Unexpected receipts payload');
      final items =
          j.whereType<Map<String, dynamic>>().map(Receipt.fromJson).toList();
      items.sort((a, b) {
        final aDate = a.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Future<Receipt> getById(String id) async {
    final r =
        await AuthenticatedHttpClient.get(_u('/$id'), headers: _headers());
    return _decode<Receipt>(r, (j) => Receipt.fromJson(j));
  }

  Future<Receipt> update(String id, Map<String, dynamic> payload) async {
    final r = await AuthenticatedHttpClient.patch(
      _u('/$id'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Receipt>(r, (j) {
      if (j is Map<String, dynamic>) return Receipt.fromJson(j);
      throw Exception('Unexpected receipt payload');
    });
  }

  Future<void> delete(String id) async {
    final uri = _u('/$id');
    final r = await AuthenticatedHttpClient.delete(uri, headers: _headers());
    if (r.statusCode >= 200 && r.statusCode < 300) return;

    String msg = r.reasonPhrase ?? 'Failed to delete receipt';
    if (r.body.isNotEmpty) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body['message'] != null) {
          msg = body['message'].toString();
        } else if (body is Map && body['error'] != null) {
          msg = body['error'].toString();
        }
      } catch (_) {}
    }

    assert(() {
      // ignore: avoid_print
      print(
        '[ReceiptsApi] DELETE $uri -> ${r.statusCode} '
        'reason=${r.reasonPhrase} body=${r.body.isEmpty ? '-' : r.body}',
      );
      return true;
    }());

    throw ReceiptsApiException(
      statusCode: r.statusCode,
      message: msg,
      url: uri,
      method: 'DELETE',
      responseBody: r.body.isEmpty ? null : r.body,
      responseHeaders: r.headers,
    );
  }

  Future<Receipt> issue(String id) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/issue'),
      headers: _headers(),
    );
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }
    if (!ok) {
      return _decode<Receipt>(
          r, (_) => throw Exception('Unexpected receipt payload'));
    }
    if (body is Map<String, dynamic>) {
      if (body.containsKey('_id') || body.containsKey('id')) {
        return Receipt.fromJson(body);
      }
      for (final key in const ['receipt', 'data', 'item']) {
        final nested = body[key];
        if (nested is Map<String, dynamic>) {
          return Receipt.fromJson(nested);
        }
        if (nested is Map) {
          return Receipt.fromJson(Map<String, dynamic>.from(nested));
        }
      }
    }
    if (r.body.trim().isEmpty) {
      // Some deployments acknowledge issue with 200/204 and no payload.
      // In that case, load the updated receipt explicitly.
      return getById(id);
    }
    throw Exception('Unexpected receipt payload');
  }

  Future<UnnumberedReceiptDraftLookup> lookupUnnumberedDraft({
    required String groupId,
  }) async {
    final uri = _u('/draft/unnumbered').replace(
      queryParameters: {'groupId': groupId},
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<UnnumberedReceiptDraftLookup>(r, (j) {
      if (j is! Map) throw Exception('Unexpected receipt draft payload');
      final map = Map<String, dynamic>.from(j);
      return UnnumberedReceiptDraftLookup.fromJson(map);
    });
  }

  Future<http.Response> previewPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf/preview'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw Exception(
        'Failed to preview PDF (${r.statusCode}): ${r.reasonPhrase}');
  }

  Future<http.Response> downloadPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw Exception(
      'Failed to download PDF (${r.statusCode}): ${r.reasonPhrase}',
    );
  }

  Future<Map<String, dynamic>> getImportJsonPromptTemplate(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/import-json/prompt-template'),
      headers: _headers(),
    );
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      throw Exception('Unexpected receipt prompt-template payload');
    });
  }

  Future<Map<String, dynamic>> importJson(
    String id,
    dynamic payload,
  ) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/import-json'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      throw Exception('Unexpected receipt import payload');
    });
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
      throw ReceiptsApiException(
        statusCode: 401,
        message: 'Not authenticated',
        url: _u('/$id/extract-image'),
        method: 'POST',
        responseBody: null,
        responseHeaders: null,
      );
    }

    final req = http.MultipartRequest('POST', _u('/$id/extract-image'));
    req.headers['Authorization'] = auth;
    req.fields['method'] = 'openai';
    req.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );

    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decode<Map<String, dynamic>>(response, (j) {
      if (j is Map<String, dynamic>) return j;
      throw Exception('Unexpected receipt extract payload');
    });
  }
}
