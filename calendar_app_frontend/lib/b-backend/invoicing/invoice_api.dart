import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/invoicing/models/manual_editor_capabilities.dart';
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

class InvoicePaymentSuggestion {
  const InvoicePaymentSuggestion({
    required this.invoiceId,
    required this.entryId,
    this.entryDate,
    this.concept,
    this.amountFormatted,
    this.confidenceLabel,
    this.confidence,
    this.reason,
    this.alreadyLinked = false,
    this.linkedInvoiceNumber,
    this.linkedInvoiceClientName,
  });

  final String invoiceId;
  final String entryId;
  final String? entryDate;
  final String? concept;
  final String? amountFormatted;
  final String? confidenceLabel;
  final num? confidence;
  final String? reason;
  final bool alreadyLinked;
  final String? linkedInvoiceNumber;
  final String? linkedInvoiceClientName;

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    final text = _string(value).toLowerCase();
    return text == 'true' || text == '1' || text == 'yes' || text == 'si';
  }

  static num? _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(_string(value).replaceAll(',', '.'));
  }

  factory InvoicePaymentSuggestion.fromJson(Map<String, dynamic> json) {
    String firstString(List<dynamic> values) {
      for (final value in values) {
        final text = _string(value);
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final existing = json['existingLink'] is Map
        ? (json['existingLink'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return InvoicePaymentSuggestion(
      invoiceId: firstString([
        json['invoiceId'],
        json['targetInvoiceId'],
        json['id'],
      ]),
      entryId: firstString([
        json['entryId'],
        json['statementEntryId'],
        json['paymentEntryId'],
      ]),
      entryDate: firstString([
        json['entryDate'],
        json['paymentDate'],
        json['date'],
      ]),
      concept: firstString([
        json['concept'],
        json['entryConcept'],
        json['paymentConcept'],
        json['description'],
      ]),
      amountFormatted: firstString([
        json['amountFormatted'],
        json['entryAmountFormatted'],
        json['paymentAmountFormatted'],
        json['totalFormatted'],
      ]),
      confidenceLabel: firstString([
        json['confidenceLabel'],
        json['scoreLabel'],
        json['matchLabel'],
      ]),
      confidence:
          _num(json['confidence'] ?? json['score'] ?? json['matchScore']),
      reason: firstString([
        json['reason'],
        json['explanation'],
        json['why'],
        json['matchReason'],
      ]),
      alreadyLinked: _bool(
        json['alreadyLinked'] ??
            json['entryAlreadyLinked'] ??
            json['hasExistingInvoiceLink'],
      ),
      linkedInvoiceNumber: firstString([
        json['linkedInvoiceNumber'],
        json['currentInvoiceNumber'],
        existing['invoiceNumber'],
      ]),
      linkedInvoiceClientName: firstString([
        json['linkedInvoiceClientName'],
        json['currentInvoiceClientName'],
        existing['clientName'],
      ]),
    );
  }
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
    String? linkStatus,
    String? seriesId,
    String? sortBy,
    String? sortDir,
  }) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (linkStatus != null && linkStatus.isNotEmpty) 'linkStatus': linkStatus,
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

      if (body['details'] is String &&
          body['details'].toString().trim().isNotEmpty) {
        details.add(body['details'].toString().trim());
      }
      addList('missing', body['missing']);
      addList('missing', body['missingFields']);
      addList('fields', body['fields']);
      addMap('errors', body['errors']);
      if (body['errors'] is List) {
        final list = body['errors'] as List;
        final parts = list
            .map((e) {
              if (e is Map) {
                final field = e['field'] ?? e['path'] ?? e['name'];
                final msg = e['message'] ?? e['msg'] ?? e['error'];
                if (field != null && msg != null) {
                  return '${field.toString()}: ${msg.toString()}';
                }
                return msg?.toString() ?? field?.toString() ?? '';
              }
              return e?.toString() ?? '';
            })
            .where((e) => e.trim().isNotEmpty)
            .toList();
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
    String? linkStatus,
    String? seriesId,
    String? sortBy,
    String? sortDir,
  }) async {
    final uri = buildListByGroupUri(
      groupId,
      status: status,
      linkStatus: linkStatus,
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

  Future<Map<String, dynamic>> getSummary({
    required String groupId,
    String? clientId,
    String? status,
    String? from,
    String? to,
    String? currency,
  }) async {
    final params = <String, String>{
      'groupId': groupId,
      if ((clientId ?? '').trim().isNotEmpty) 'clientId': clientId!.trim(),
      if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
    final uri = Uri.parse('$_base/summary').replace(queryParameters: params);
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map) return Map<String, dynamic>.from(j);
      throw Exception('Unexpected invoice summary payload');
    });
  }

  Future<Map<String, dynamic>> getVatAudit({
    required String groupId,
    String? clientId,
    String? status,
    String? from,
    String? to,
    String? currency,
  }) async {
    final params = <String, String>{
      'groupId': groupId,
      if ((clientId ?? '').trim().isNotEmpty) 'clientId': clientId!.trim(),
      if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
    final uri = Uri.parse('$_base/vat-audit').replace(queryParameters: params);
    if (kDebugMode) debugPrint('[InvoicesApi] GET $uri');
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    final data = _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map) return Map<String, dynamic>.from(j);
      throw Exception('Unexpected invoice VAT audit payload');
    });
    if (kDebugMode) {
      debugPrint(
        '[InvoicesApi] vat-audit status=${r.statusCode} '
        'count=${data['count']} mismatchCount=${data['mismatchCount']} '
        'rows=${(data['rows'] as List?)?.length ?? 0}',
      );
    }
    return data;
  }

  Future<http.Response> exportVatAuditExcel({
    required String groupId,
    String? clientId,
    String? status,
    String? from,
    String? to,
    String? currency,
  }) async {
    final params = <String, String>{
      'groupId': groupId,
      if ((clientId ?? '').trim().isNotEmpty) 'clientId': clientId!.trim(),
      if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
    final uri = Uri.parse('$_base/vat-audit/export.xlsx')
        .replace(queryParameters: params);
    final headers = _headers();
    headers['Accept'] =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    final r = await AuthenticatedHttpClient.get(uri, headers: headers);
    if (r.statusCode >= 200 && r.statusCode < 300) return r;

    String msg = r.reasonPhrase ?? 'Failed to export VAT audit Excel';
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

  Future<List<Map<String, dynamic>>> searchManualLinkCandidates({
    required String groupId,
    String? q,
    num? amount,
    String status = 'issued',
    int limit = 20,
  }) async {
    final params = <String, String>{
      'groupId': groupId,
      if ((q ?? '').trim().isNotEmpty) 'q': q!.trim(),
      if (amount != null) 'amount': amount.toString(),
      if (status.trim().isNotEmpty) 'status': status.trim(),
      'limit': limit.clamp(1, 100).toString(),
    };
    final uri =
        Uri.parse('$_base/search/manual-link').replace(queryParameters: params);
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<List<Map<String, dynamic>>>(r, (j) {
      if (j is! Map) return const <Map<String, dynamic>>[];
      final raw = j['invoices'];
      if (raw is! List) return const <Map<String, dynamic>>[];
      return raw
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList(growable: false);
    });
  }

  Future<List<InvoicePaymentSuggestion>> suggestPaymentLinks({
    required String groupId,
    String status = 'issued',
    String linkStatus = 'unlinked',
    String? from,
    String? to,
    int limit = 100,
  }) async {
    final params = <String, String>{
      if (status.trim().isNotEmpty) 'status': status.trim(),
      if (linkStatus.trim().isNotEmpty) 'linkStatus': linkStatus.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      'limit': limit.clamp(1, 500).toString(),
    };
    final uri = Uri.parse('$_base/group/$groupId/link-suggestions')
        .replace(queryParameters: params);
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<List<InvoicePaymentSuggestion>>(r, (j) {
      final raw = j is Map ? (j['suggestions'] ?? j['rows'] ?? j['items']) : j;
      if (raw is! List) return const <InvoicePaymentSuggestion>[];
      return raw
          .whereType<Map>()
          .map((item) => InvoicePaymentSuggestion.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .where((item) => item.invoiceId.isNotEmpty && item.entryId.isNotEmpty)
          .toList(growable: false);
    });
  }

  Future<http.Response> exportConceptsExcel({
    required String groupId,
    String? clientId,
    String? status,
    String? from,
    String? to,
    String? currency,
  }) async {
    final params = <String, String>{
      'groupId': groupId,
      if ((clientId ?? '').trim().isNotEmpty) 'clientId': clientId!.trim(),
      if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
    final uri = Uri.parse('$_base/concepts/export.xlsx')
        .replace(queryParameters: params);
    final headers = _headers();
    headers['Accept'] =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    final r = await AuthenticatedHttpClient.get(uri, headers: headers);
    if (r.statusCode >= 200 && r.statusCode < 300) return r;

    String msg = r.reasonPhrase ?? 'Failed to export invoice concepts Excel';
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

  Future<Map<String, dynamic>> patchSuspicionReview(
    String invoiceId, {
    required String status,
    String? notes,
  }) async {
    final uri = _u('/$invoiceId/suspicion-review');
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }
    final r = await AuthenticatedHttpClient.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map) return Map<String, dynamic>.from(j);
      throw Exception('Unexpected invoice suspicion review payload');
    });
  }

  Future<Map<String, dynamic>> previewAccountantCompare({
    required List<int> bytes,
    required String fileName,
    required String groupId,
    String? status,
    String? from,
    String? to,
    String? clientId,
    String? currency,
    String? tolerance,
  }) async {
    final uri = _u('/accountant-compare/preview');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(
      await AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: false,
      ),
    );
    req.fields['groupId'] = groupId.trim();
    if ((status ?? '').trim().isNotEmpty) req.fields['status'] = status!.trim();
    if ((from ?? '').trim().isNotEmpty) req.fields['from'] = from!.trim();
    if ((to ?? '').trim().isNotEmpty) req.fields['to'] = to!.trim();
    if ((clientId ?? '').trim().isNotEmpty) {
      req.fields['clientId'] = clientId!.trim();
    }
    if ((currency ?? '').trim().isNotEmpty) {
      req.fields['currency'] = currency!.trim();
    }
    if ((tolerance ?? '').trim().isNotEmpty) {
      req.fields['tolerance'] = tolerance!.trim();
    }
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName.trim().isEmpty ? 'accountant.xlsx' : fileName.trim(),
      ),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decode<Map<String, dynamic>>(response, (j) {
      if (j is Map) return Map<String, dynamic>.from(j);
      throw Exception('Unexpected accountant compare payload');
    });
  }

  Future<Invoice> getById(String id) async {
    final r =
        await AuthenticatedHttpClient.get(_u('/$id'), headers: _headers());
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

  /// GET /invoices/pdf/all  (zip with filtered invoice PDFs)
  /// [queryParams] must include 'groupId'; may include year, month, quarter,
  /// from, to, status (comma-separated), dateField, or invoiceIds
  /// (comma-separated) for an exact visual selection.
  Future<http.Response> downloadAllPdfsZip(
    String groupId, {
    Map<String, String>? queryParams,
  }) async {
    final params = queryParams ?? {'groupId': groupId};
    final uri = Uri.parse('$_base/pdf/all').replace(queryParameters: params);
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

  /// GET /invoices/manual-editor/capabilities?lang=es|en
  Future<ManualEditorCapabilities> getManualEditorCapabilities({
    required String lang,
    String? groupId,
  }) async {
    final uri = Uri.parse('$_base/manual-editor/capabilities')
        .replace(queryParameters: {
      'lang': lang,
      if (groupId != null && groupId.trim().isNotEmpty) 'groupId': groupId,
    });
    debugPrint('[ManualEditorCaps] GET $uri');
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    debugPrint(
        '[ManualEditorCaps] HTTP ${r.statusCode} body=${r.body.length > 300 ? r.body.substring(0, 300) : r.body}');
    return _decode<ManualEditorCapabilities>(r, (j) {
      if (j is Map) {
        return ManualEditorCapabilities.fromJson(
          Map<String, dynamic>.from(j),
        );
      }
      throw Exception('Unexpected capabilities payload: ${j.runtimeType}');
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
