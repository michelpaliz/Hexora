import 'dart:convert';

import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class ReceiptsApiException implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;
  final Map<String, String>? responseHeaders;
  final Uri url;
  final String method;

  ReceiptsApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.method,
    required this.responseBody,
    required this.responseHeaders,
  });

  @override
  String toString() => 'Exception: $message';
}

class ReceiptsApi {
  final String _base = '${ApiConstants.baseUrl}/receipts';

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await TokenService.loadToken()}',
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
      url: r.request?.url ?? _u(),
      method: r.request?.method ?? 'REQUEST',
      responseBody: r.body.isEmpty ? null : r.body,
      responseHeaders: r.headers,
    );
  }

  Future<Receipt> create(Receipt receipt) async {
    final r = await http.post(
      _u(),
      headers: await _headers(),
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
    final r = await http.get(uri, headers: await _headers());
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
    final r = await http.get(_u('/$id'), headers: await _headers());
    return _decode<Receipt>(r, (j) => Receipt.fromJson(j));
  }

  Future<Receipt> update(String id, Map<String, dynamic> payload) async {
    final r = await http.patch(
      _u('/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Receipt>(r, (j) {
      if (j is Map<String, dynamic>) return Receipt.fromJson(j);
      throw Exception('Unexpected receipt payload');
    });
  }

  Future<void> delete(String id) async {
    final uri = _u('/$id');
    final r = await http.delete(uri, headers: await _headers());
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
    final r = await http.post(_u('/$id/issue'), headers: await _headers());
    return _decode<Receipt>(r, (j) {
      if (j is Map<String, dynamic>) return Receipt.fromJson(j);
      throw Exception('Unexpected receipt payload');
    });
  }

  Future<http.Response> previewPdf(String id) async {
    final r = await http.get(_u('/$id/pdf/preview'), headers: await _headers());
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw Exception('Failed to preview PDF (${r.statusCode}): ${r.reasonPhrase}');
  }

  Future<http.Response> downloadPdf(String id) async {
    final r = await http.get(_u('/$id/pdf'), headers: await _headers());
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw Exception(
      'Failed to download PDF (${r.statusCode}): ${r.reasonPhrase}',
    );
  }
}

