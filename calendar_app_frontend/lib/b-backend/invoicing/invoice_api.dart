import 'dart:convert';

import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class InvoicesApi {
  final String _base = '${ApiConstants.baseUrl}/invoices';

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

    if (ok) {
      return map(body);
    }

    String message = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw Exception(message);
  }

  Future<Invoice> create(Invoice invoice) async {
    final r = await http.post(
      _u(),
      headers: await _headers(),
      body: jsonEncode(invoice.toCreatePayload()),
    );
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  Future<List<Invoice>> listByGroup(String groupId, {String? status}) async {
    final uri = status == null
        ? _u('/group/$groupId')
        : _u('/group/$groupId?status=$status');
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Invoice>>(r, (j) {
      if (j is! List) throw Exception('Unexpected invoices payload');
      final items =
          j.whereType<Map<String, dynamic>>().map(Invoice.fromJson).toList();
      items.sort((a, b) {
        final aDate = a.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Future<Invoice> getById(String id) async {
    final r = await http.get(_u('/$id'), headers: await _headers());
    return _decode<Invoice>(r, (j) => Invoice.fromJson(j));
  }

  /// POST /invoices/:id/issue  -> locks invoice, assigns number/issueDate/status
  Future<Invoice> issue(String id) async {
    final r = await http.post(_u('/$id/issue'), headers: await _headers());
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  /// GET /invoices/:id/pdf/preview  (inline PDF for drafts/issued)
  Future<http.Response> previewPdf(String id) async {
    final r = await http.get(
      _u('/$id/pdf/preview'),
      headers: await _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw Exception(
        'Failed to preview PDF (${r.statusCode}): ${r.reasonPhrase}');
  }

  /// GET /invoices/:id/pdf  (attachment PDF for issued)
  Future<http.Response> downloadPdf(String id) async {
    final r = await http.get(
      _u('/$id/pdf'),
      headers: await _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw Exception(
        'Failed to download PDF (${r.statusCode}): ${r.reasonPhrase}');
  }

  /// DELETE /invoices/:id  (useful for drafts cleanup, if supported by backend)
  Future<void> delete(String id) async {
    final r = await http.delete(_u('/$id'), headers: await _headers());
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    String msg = r.reasonPhrase ?? 'Failed to delete invoice';
    if (r.body.isNotEmpty) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body['message'] != null) {
          msg = body['message'].toString();
        }
      } catch (_) {}
    }
    throw Exception(msg);
  }
}
