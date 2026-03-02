import 'dart:convert';

import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class InvoicesApiException implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;
  final Map<String, String>? responseHeaders;
  final Uri url;
  final String method;

  InvoicesApiException({
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

class InvoicesApi {
  final String _base = '${ApiConstants.baseUrl}/invoices';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Uri _u([String path = '']) => Uri.parse('$_base$path');

  Uri buildMarkSentUri(String invoiceId) => _u('/$invoiceId/mark-sent');
  Uri buildMarkUnsentUri(String invoiceId) => _u('/$invoiceId/mark-unsent');

  Uri buildListByGroupUri(
    String groupId, {
    String? status,
    String? seriesId,
    String? sortBy,
    String? sortDir,
  }) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (seriesId != null && seriesId.isNotEmpty) 'seriesId': seriesId,
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (sortDir != null && sortDir.isNotEmpty) 'sortDir': sortDir,
    };
    return query.isEmpty
        ? _u('/group/$groupId')
        : _u('/group/$groupId?${Uri(queryParameters: query).query}');
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

    if (ok) {
      return map(body);
    }

    String message = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }

    if (body is Map) {
      final details = <String>[];

      void addList(String label, dynamic value) {
        if (value is! List) return;
        final items = value
            .map((e) => e == null ? '' : e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          details.add('$label: ${items.join(', ')}');
        }
      }

      void addMap(String label, dynamic value) {
        if (value is! Map) return;
        final parts = value.entries
            .map((e) => '${e.key}: ${e.value}')
            .where((e) => e.trim().isNotEmpty)
            .toList();
        if (parts.isNotEmpty) {
          details.add('$label: ${parts.join(', ')}');
        }
      }

      if (body['details'] is String && body['details'].toString().trim().isNotEmpty) {
        details.add(body['details'].toString().trim());
      }
      addList('missing', body['missing']);
      addList('missing', body['missingFields']);
      addList('fields', body['fields']);
      addMap('errors', body['errors']);
      if (body['errors'] is List) {
        final list = body['errors'] as List;
        final parts = list.map((e) {
          if (e is Map) {
            final field = e['field'] ?? e['path'] ?? e['name'];
            final msg = e['message'] ?? e['msg'] ?? e['error'];
            if (field != null && msg != null) {
              return '${field.toString()}: ${msg.toString()}';
            }
            return msg?.toString() ?? field?.toString() ?? '';
          }
          return e?.toString() ?? '';
        }).where((e) => e.trim().isNotEmpty).toList();
        if (parts.isNotEmpty) details.add('errors: ${parts.join(', ')}');
      }

      if (details.isNotEmpty) {
        message = '$message (${details.join(' · ')})';
      }
    }

    throw Exception(message);
  }

  Future<Invoice> create(Invoice invoice) async {
    final r = await AuthenticatedHttpClient.post(
      _u(),
      headers: _headers(),
      body: jsonEncode(invoice.toCreatePayload()),
    );
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  Future<List<Invoice>> listByGroup(
    String groupId, {
    String? status,
    String? seriesId,
    String? sortBy,
    String? sortDir,
  }) async {
    final uri = buildListByGroupUri(
      groupId,
      status: status,
      seriesId: seriesId,
      sortBy: sortBy,
      sortDir: sortDir,
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<List<Invoice>>(r, (j) {
      if (j is! List) throw Exception('Unexpected invoices payload');
      return j
          .whereType<Map<String, dynamic>>()
          .map(Invoice.fromJson)
          .toList(growable: false);
    });
  }

  Future<Invoice> getById(String id) async {
    final r = await AuthenticatedHttpClient.get(_u('/$id'), headers: _headers());
    return _decode<Invoice>(r, (j) => Invoice.fromJson(j));
  }

  /// POST /invoices/:id/issue  -> locks invoice, assigns number/issueDate/status
  Future<Invoice> issue(String id) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/issue'),
      headers: _headers(),
    );
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  /// GET /invoices/:id/pdf/preview  (inline PDF for drafts/issued)
  Future<http.Response> previewPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf/preview'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = r.body.trim();
    final detail = body.isEmpty ? '' : ' - $body';
    throw Exception(
        'Failed to preview PDF (${r.statusCode}): ${r.reasonPhrase}$detail');
  }

  /// GET /invoices/:id/pdf  (attachment PDF for issued)
  Future<http.Response> downloadPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw Exception(
        'Failed to download PDF (${r.statusCode}): ${r.reasonPhrase}');
  }

  /// GET /invoices/pdf/all?groupId=<id>  (zip with all invoice PDFs)
  Future<http.Response> downloadAllPdfsZip(String groupId) async {
    final uri = Uri.parse('$_base/pdf/all')
        .replace(queryParameters: {'groupId': groupId});
    final headers = _headers();
    headers['Accept'] = 'application/zip';
    final r = await AuthenticatedHttpClient.get(uri, headers: headers);
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    String msg = r.reasonPhrase ?? 'Failed to download ZIP';
    if (r.body.isNotEmpty) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body['message'] != null) {
          msg = body['message'].toString();
        } else if (body is Map && body['error'] != null) {
          msg = body['error'].toString();
        } else if (body is String && body.trim().isNotEmpty) {
          msg = body.trim();
        }
      } catch (_) {
        if (r.body.trim().isNotEmpty) msg = r.body.trim();
      }
    }
    throw InvoicesApiException(
      statusCode: r.statusCode,
      message: msg,
      url: uri,
      method: 'GET',
      responseBody: r.body.isEmpty ? null : r.body,
      responseHeaders: r.headers,
    );
  }

  Future<Invoice> updateBillingName(
    String id, {
    String? billingName,
    String? addressStreet,
    String? addressCity,
    String? addressPostalCode,
    String? addressProvince,
    String? addressCountry,
    String? entityType,
    String? reason,
  }) async {
    final uri = _u('/$id/billing-name');
    final payload = <String, dynamic>{
      if (billingName != null) 'billingName': billingName,
      if (addressStreet != null) 'addressStreet': addressStreet,
      if (addressCity != null) 'addressCity': addressCity,
      if (addressPostalCode != null) 'addressPostalCode': addressPostalCode,
      if (addressProvince != null) 'addressProvince': addressProvince,
      if (addressCountry != null) 'addressCountry': addressCountry,
      if (entityType != null) 'entityType': entityType,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    if (payload.isEmpty) {
      throw Exception('No billing fields provided');
    }
    final r = await AuthenticatedHttpClient.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  Future<Invoice> updateDraft(String id, Map<String, dynamic> payload) async {
    final uri = _u('/$id/draft');
    final r = await AuthenticatedHttpClient.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  Future<Invoice> markInvoiceSent(
    String id, {
    String? channel,
    DateTime? sentAt,
  }) async {
    final payload = <String, dynamic>{
      if (channel != null && channel.trim().isNotEmpty) 'channel': channel,
      if (sentAt != null) 'sentAt': sentAt.toUtc().toIso8601String(),
    };
    final r = await AuthenticatedHttpClient.post(
      buildMarkSentUri(id),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  Future<Invoice> markInvoiceUnsent(String id) async {
    final r = await AuthenticatedHttpClient.post(
      buildMarkUnsentUri(id),
      headers: _headers(),
      body: jsonEncode(const <String, dynamic>{}),
    );
    return _decode<Invoice>(r, (j) {
      if (j is Map<String, dynamic>) return Invoice.fromJson(j);
      throw Exception('Unexpected invoice payload');
    });
  }

  /// DELETE /invoices/:id  (useful for drafts cleanup, if supported by backend)
  Future<void> delete(String id) async {
    final uri = _u('/$id');
    final r = await AuthenticatedHttpClient.delete(uri, headers: _headers());
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    String msg = r.reasonPhrase ?? 'Failed to delete invoice';
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
        '[InvoicesApi] DELETE $uri -> ${r.statusCode} '
        'reason=${r.reasonPhrase} body=${r.body.isEmpty ? '-' : r.body}',
      );
      return true;
    }());

    throw InvoicesApiException(
      statusCode: r.statusCode,
      message: msg,
      url: uri,
      method: 'DELETE',
      responseBody: r.body.isEmpty ? null : r.body,
      responseHeaders: r.headers,
    );
  }
}
