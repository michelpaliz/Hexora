import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:http/http.dart' as http;

class RecurringReceiptsApi extends RecurringInvoicesApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/recurring-receipts'
      : '${ApiConstants.baseUrl}/api/recurring-receipts';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Map<String, String> _headers() => const <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      };

  T _decode<T>(
    http.Response r, {
    required Uri url,
    required String method,
    required T Function(dynamic json) map,
  }) {
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
    } else if (body is Map && body['error'] != null) {
      msg = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body.trim();
    }

    final ex = RecurringInvoicesApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    if (kDebugMode) debugPrint(ex.toString());
    throw ex;
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final uri = _u();
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  @override
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final uri = _u('/$id');
    final r = await AuthenticatedHttpClient.put(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'PUT',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> list({
    String? groupId,
    String? status,
  }) async {
    final query = <String, String>{
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final uri = _u('', query.isEmpty ? null : query);
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is List) {
          return j
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (j is Map && j['series'] is List) {
          return (j['series'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (j is Map && j['items'] is List) {
          return (j['items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  @override
  Future<Map<String, dynamic>> preview(Map<String, dynamic> payload) async {
    final uri = _u('/preview');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  @override
  Future<Map<String, dynamic>> cancel(String id) async {
    final uri = _u('/$id/cancel');
    final r = await AuthenticatedHttpClient.post(uri, headers: _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  @override
  Future<Map<String, dynamic>> run() async {
    final uri = _u('/run');
    final r = await AuthenticatedHttpClient.post(uri, headers: _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Invoice _invoiceFromReceipt(Receipt r) {
    final subtotal = r.subtotal ??
        r.lines.fold<num>(0, (sum, line) {
          final total = line.total ?? (line.quantity * line.unitPrice);
          return sum + total;
        });
    final total = r.total ?? subtotal;
    final tax = total - subtotal;
    final lines = <InvoiceLine>[];
    for (var i = 0; i < r.lines.length; i++) {
      final line = r.lines[i];
      final lineSubtotal = line.quantity * line.unitPrice;
      final lineTotal = line.total ?? lineSubtotal;
      lines.add(
        InvoiceLine(
          invoiceId: r.id,
          position: i + 1,
          description: line.description,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          taxRate: 0,
          lineSubtotal: lineSubtotal,
          lineTax: lineTotal - lineSubtotal,
          lineTotal: lineTotal,
        ),
      );
    }
    return Invoice(
      id: r.id,
      invoiceNumber: (r.receiptNumber ?? '').trim(),
      groupId: r.groupId,
      clientId: r.clientId,
      pdfUrl: r.pdfUrl,
      currency: 'EUR',
      registeredAt: r.registeredAt,
      status: r.status,
      issueDate: r.issueDate,
      subtotal: subtotal,
      taxTotal: tax,
      total: total,
      notes: r.notes,
      occurrenceDate: r.issueDate ?? r.registeredAt,
      lines: lines,
    );
  }

  @override
  Future<({int count, List<Invoice> invoices})> listGeneratedInvoices(
    String seriesId,
  ) async {
    final uri = _u('/$seriesId/receipts');
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode(r, url: uri, method: 'GET', map: (j) {
      List<Receipt> receipts = <Receipt>[];
      if (j is Map) {
        final rawList = j['receipts'] ?? j['invoices'] ?? j['items'];
        if (rawList is List) {
          receipts = rawList
              .whereType<Map<String, dynamic>>()
              .map(Receipt.fromJson)
              .toList();
        }
        final rawCount = j['count'];
        final count = rawCount is num ? rawCount.toInt() : receipts.length;
        return (
          count: count,
          invoices: receipts.map(_invoiceFromReceipt).toList(growable: false),
        );
      }
      if (j is List) {
        receipts =
            j.whereType<Map<String, dynamic>>().map(Receipt.fromJson).toList();
        return (
          count: receipts.length,
          invoices: receipts.map(_invoiceFromReceipt).toList(growable: false),
        );
      }
      return (count: 0, invoices: <Invoice>[]);
    });
  }
}
