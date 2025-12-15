import 'dart:convert';

import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class InvoiceLinesApi {
  final String _base = '${ApiConstants.baseUrl}/invoices';

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await TokenService.loadToken()}',
      };

  Uri _u(String invoiceId, [String path = '', Map<String, String>? q]) {
    return Uri.parse('$_base/$invoiceId/lines$path')
        .replace(queryParameters: q);
  }

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

    String msg = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      msg = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body.trim();
    }
    throw Exception(msg);
  }

  Future<List<InvoiceLine>> list(String invoiceId) async {
    final r = await http.get(_u(invoiceId), headers: await _headers());
    return _decode<List<InvoiceLine>>(r, (j) {
      if (j is! List) throw Exception('Unexpected invoice lines payload');
      return j
          .whereType<Map<String, dynamic>>()
          .map(InvoiceLine.fromJson)
          .toList();
    });
  }

  Future<InvoiceLine> create(String invoiceId, InvoiceLine line) async {
    final body = {
      'position': line.position,
      'description': line.description,
      'quantity': line.quantity,
      'unitPrice': line.unitPrice,
      'taxRate': line.taxRate,
    };
    final r = await http.post(
      _u(invoiceId),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode<InvoiceLine>(r, (j) {
      if (j is Map<String, dynamic>) return InvoiceLine.fromJson(j);
      throw Exception('Unexpected invoice line payload');
    });
  }

  Future<InvoiceLine> update(
    String invoiceId,
    String lineId,
    Map<String, dynamic> patch,
  ) async {
    final r = await http.patch(
      _u(invoiceId, '/$lineId'),
      headers: await _headers(),
      body: jsonEncode(patch),
    );
    return _decode<InvoiceLine>(r, (j) {
      if (j is Map<String, dynamic>) return InvoiceLine.fromJson(j);
      throw Exception('Unexpected invoice line payload');
    });
  }

  Future<void> delete(String invoiceId, String lineId) async {
    final r = await http.delete(
      _u(invoiceId, '/$lineId'),
      headers: await _headers(),
    );
    _decode<void>(r, (_) => null);
  }
}
