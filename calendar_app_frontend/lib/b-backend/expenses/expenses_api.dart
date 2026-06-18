import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ExpensesApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;

  ExpensesApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.method,
    required this.responseBody,
  });

  @override
  String toString() {
    final body = (responseBody == null || responseBody!.trim().isEmpty)
        ? ''
        : '\nbody: ${responseBody!.trim()}';
    return 'Expenses API ($statusCode) $method $url: $message$body';
  }
}

class ExpenseBatchIncidentExport {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  const ExpenseBatchIncidentExport({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}

class ExpensesApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/expenses'
      : '${ApiConstants.baseUrl}/api/expenses';
  final String _apiRoot = ApiConstants.baseUrl.endsWith('/api')
      ? ApiConstants.baseUrl
      : '${ApiConstants.baseUrl}/api';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Uri _apiUri([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_apiRoot$path').replace(queryParameters: query);

  MediaType _mediaTypeForFileName(String? fileName) {
    final lower = (fileName ?? '').toLowerCase().trim();
    if (lower.endsWith('.pdf')) {
      return MediaType('application', 'pdf');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.jpe')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.json')) {
      return MediaType('application', 'json');
    }
    return MediaType('application', 'octet-stream');
  }

  String? _filenameFromContentDisposition(String? value) {
    final header = value?.trim() ?? '';
    if (header.isEmpty) return null;
    final encodedMatch = RegExp(
      r'''filename\*=UTF-8''([^;]+)''',
      caseSensitive: false,
    ).firstMatch(header);
    if (encodedMatch != null) {
      final encoded = encodedMatch.group(1)?.trim();
      if (encoded != null && encoded.isNotEmpty) {
        return Uri.decodeComponent(encoded.replaceAll('"', ''));
      }
    }
    final quotedMatch = RegExp(
      r'''filename="?([^";]+)"?''',
      caseSensitive: false,
    ).firstMatch(header);
    final fileName = quotedMatch?.group(1)?.trim();
    return (fileName == null || fileName.isEmpty) ? null : fileName;
  }

  Future<Map<String, dynamic>> _sendBatchMultipartRequest({
    required String endpoint,
    required List<Uint8List> documentFilesBytes,
    required List<String> documentFileNames,
    String? groupId,
    Map<String, dynamic>? payload,
    Map<String, String>? extraFields,
  }) async {
    final uri = _u(endpoint);
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers(json: false));
    if (payload != null) {
      req.fields['json'] = jsonEncode(payload);
    }
    final trimmedGroupId = groupId?.trim() ?? '';
    if (trimmedGroupId.isNotEmpty) {
      req.fields['groupId'] = trimmedGroupId;
    }
    if (extraFields != null) {
      for (final entry in extraFields.entries) {
        final value = entry.value.trim();
        if (value.isEmpty) continue;
        req.fields[entry.key] = value;
      }
    }

    for (var i = 0; i < documentFilesBytes.length; i++) {
      final bytes = documentFilesBytes[i];
      final name = documentFileNames[i].trim().isEmpty
          ? 'document-$i'
          : documentFileNames[i].trim();
      req.files.add(
        http.MultipartFile.fromBytes(
          'documents',
          bytes,
          filename: name,
          contentType: _mediaTypeForFileName(name),
        ),
      );
    }

    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    final out = _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
    out['_statusCode'] = r.statusCode;
    return out;
  }

  Future<Map<String, String>> _headers({bool json = true}) {
    return AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: json,
      extra: json ? const {'Content-Type': 'application/json'} : null,
    );
  }

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
    if (r.statusCode == 413) {
      msg = 'Payload too large for server upload limits.';
    }
    if (body is Map && body['message'] != null) {
      msg = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      msg = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body.trim();
    }

    final ex = ExpensesApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
    );
    if (kDebugMode) debugPrint(ex.toString());
    throw ex;
  }

  Future<Map<String, dynamic>> uploadExpense({
    required List<int> bytes,
    required String filename,
    required String vendorName,
    required String issueDate,
    required String total,
    String? groupId,
    String? vendorTaxId,
    String? invoiceNumber,
    String? dueDate,
    String? taxTotal,
    String? currency,
    String? notes,
    String? clientId,
    String? statementEntryId,
    String? providerId,
    List<Map<String, dynamic>>? lines,
    String? expenseType,
    Map<String, dynamic>? advancePayment,
    Map<String, dynamic>? finalSettlement,
    Map<String, dynamic>? withholding,
    String? discountAmount,
    String? discountPercent,
    String? subtotal,
    List<Map<String, dynamic>>? vatBreakdown,
    bool? useSummaryTotals,
    String? taxSource,
  }) async {
    final uri = _u();
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers(json: false));
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _mediaTypeForFileName(filename),
      ),
    );
    req.fields['vendorName'] = vendorName;
    req.fields['issueDate'] = issueDate;
    if (total.isNotEmpty) {
      req.fields['total'] = total;
    }
    if (groupId != null && groupId.isNotEmpty) {
      req.fields['groupId'] = groupId;
    }
    if (vendorTaxId != null && vendorTaxId.isNotEmpty) {
      req.fields['vendorTaxId'] = vendorTaxId;
    }
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      req.fields['invoiceNumber'] = invoiceNumber;
    }
    if (dueDate != null && dueDate.isNotEmpty) {
      req.fields['dueDate'] = dueDate;
    }
    if (taxTotal != null && taxTotal.isNotEmpty) {
      req.fields['taxTotal'] = taxTotal;
    }
    if (subtotal != null && subtotal.isNotEmpty) {
      req.fields['subtotal'] = subtotal;
    }
    if (currency != null && currency.isNotEmpty) {
      req.fields['currency'] = currency;
    }
    if (notes != null && notes.isNotEmpty) {
      req.fields['notes'] = notes;
    }
    if (clientId != null && clientId.isNotEmpty) {
      req.fields['clientId'] = clientId;
    }
    if (statementEntryId != null && statementEntryId.isNotEmpty) {
      req.fields['statementEntryId'] = statementEntryId;
    }
    if (providerId != null && providerId.isNotEmpty) {
      req.fields['providerId'] = providerId;
    }
    if (expenseType != null && expenseType.isNotEmpty) {
      req.fields['expenseType'] = expenseType;
    }
    if (advancePayment != null && advancePayment.isNotEmpty) {
      for (final entry in advancePayment.entries) {
        final value = entry.value;
        if (value == null) continue;
        req.fields['advancePayment[${entry.key}]'] = value.toString();
      }
    }
    if (finalSettlement != null && finalSettlement.isNotEmpty) {
      for (final entry in finalSettlement.entries) {
        final value = entry.value;
        if (value == null) continue;
        req.fields['finalSettlement[${entry.key}]'] = value.toString();
      }
    }
    if (withholding != null && withholding.isNotEmpty) {
      for (final entry in withholding.entries) {
        final value = entry.value;
        if (value == null) continue;
        req.fields['withholding[${entry.key}]'] = value.toString();
      }
    }
    if (discountAmount != null && discountAmount.isNotEmpty) {
      req.fields['discountAmount'] = discountAmount;
    }
    if (discountPercent != null && discountPercent.isNotEmpty) {
      req.fields['discountPercent'] = discountPercent;
    }
    if (useSummaryTotals != null) {
      req.fields['useSummaryTotals'] = useSummaryTotals ? 'true' : 'false';
    }
    if (taxSource != null && taxSource.isNotEmpty) {
      req.fields['taxSource'] = taxSource;
    }
    if (lines != null && lines.isNotEmpty) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final entry in line.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value == null) continue;
          req.fields['lines[$i][$key]'] = value.toString();
        }
      }
    }
    if (vatBreakdown != null && vatBreakdown.isNotEmpty) {
      for (var i = 0; i < vatBreakdown.length; i++) {
        final row = vatBreakdown[i];
        for (final entry in row.entries) {
          final value = entry.value;
          if (value == null) continue;
          req.fields['vatBreakdown[$i][${entry.key}]'] = value.toString();
        }
      }
    }
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> list({
    int page = 1,
    int size = 50,
    String? groupId,
    String? providerId,
    String? clientId,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (groupId != null && groupId.trim().isNotEmpty) {
      params['groupId'] = groupId.trim();
    }
    if (providerId != null && providerId.trim().isNotEmpty) {
      params['providerId'] = providerId.trim();
    }
    if (clientId != null && clientId.trim().isNotEmpty) {
      params['clientId'] = clientId.trim();
    }
    final uri = _u('', params);
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
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
        if (j is Map) {
          final items =
              j['items'] ?? j['data'] ?? j['results'] ?? j['expenses'];
          if (items is List) {
            return items
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<List<Map<String, dynamic>>> listAll({
    int pageSize = 100,
    String? groupId,
    String? providerId,
    String? clientId,
    int maxPages = 100,
  }) async {
    final safePageSize = pageSize <= 0 ? 100 : pageSize;
    final safeMaxPages = maxPages <= 0 ? 100 : maxPages;
    final all = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var page = 1; page <= safeMaxPages; page++) {
      final items = await list(
        page: page,
        size: safePageSize,
        groupId: groupId,
        providerId: providerId,
        clientId: clientId,
      );
      if (items.isEmpty) {
        break;
      }

      var addedThisPage = 0;
      for (final item in items) {
        final id = (item['id'] ?? item['_id'] ?? item['expenseId'] ?? '')
            .toString()
            .trim();
        if (id.isNotEmpty) {
          if (!seenIds.add(id)) continue;
        }
        all.add(item);
        addedThisPage++;
      }

      // Safety valve in case the backend repeats the same page payload.
      if (addedThisPage == 0 || items.length < safePageSize) {
        break;
      }
    }

    return all;
  }

  Future<Map<String, dynamic>> updateExpense({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final uri = _u('/$id');
    final r = await AuthenticatedHttpClient.put(
      uri,
      headers: await _headers(),
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

  Future<Map<String, dynamic>> reprocessExpenseOcr({
    required String expenseId,
    required String groupId,
    bool apply = false,
  }) async {
    final trimmedExpenseId = expenseId.trim();
    final trimmedGroupId = groupId.trim();
    if (trimmedExpenseId.isEmpty) {
      throw ArgumentError('expenseId is required');
    }
    if (trimmedGroupId.isEmpty) {
      throw ArgumentError('groupId is required');
    }
    final uri = _u('/${Uri.encodeComponent(trimmedExpenseId)}/reprocess-ocr');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'groupId': trimmedGroupId,
        'apply': apply,
      }),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> startBulkExpenseOcrReprocess({
    required String groupId,
    required List<String> expenseIds,
    String reason = 'zero_vat_review',
    bool apply = false,
  }) async {
    final trimmedGroupId = groupId.trim();
    final normalizedIds = expenseIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (trimmedGroupId.isEmpty) {
      throw ArgumentError('groupId is required');
    }
    if (normalizedIds.isEmpty) {
      throw ArgumentError('expenseIds cannot be empty');
    }
    final uri = _u('/reprocess-ocr/bulk');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'groupId': trimmedGroupId,
        'expenseIds': normalizedIds,
        'reason': reason,
        'apply': apply,
      }),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getExpenseOcrReprocessJob({
    required String jobId,
    required String groupId,
  }) async {
    final trimmedJobId = jobId.trim();
    final trimmedGroupId = groupId.trim();
    if (trimmedJobId.isEmpty) {
      throw ArgumentError('jobId is required');
    }
    if (trimmedGroupId.isEmpty) {
      throw ArgumentError('groupId is required');
    }
    final uri = _u(
      '/reprocess-ocr/jobs/${Uri.encodeComponent(trimmedJobId)}',
      {'groupId': trimmedGroupId},
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> applyExpenseOcrReprocessSuggestions({
    required String groupId,
    required List<Map<String, dynamic>> items,
  }) async {
    final trimmedGroupId = groupId.trim();
    if (trimmedGroupId.isEmpty) {
      throw ArgumentError('groupId is required');
    }
    if (items.isEmpty) {
      throw ArgumentError('items cannot be empty');
    }
    final uri = _u('/reprocess-ocr/apply');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'groupId': trimmedGroupId,
        'items': items,
      }),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> fetchExpenseOcrReprocessCandidates({
    required String groupId,
    String reason = 'zero_vat_review',
  }) async {
    final trimmedGroupId = groupId.trim();
    if (trimmedGroupId.isEmpty) {
      throw ArgumentError('groupId is required');
    }
    final uri = _u('/reprocess-ocr/candidates', {
      'groupId': trimmedGroupId,
      'reason': reason,
    });
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<void> deleteExpense(String id) async {
    final uri = _u('/$id');
    final r =
        await AuthenticatedHttpClient.delete(uri, headers: await _headers());
    _decode<void>(
      r,
      url: uri,
      method: 'DELETE',
      map: (_) {},
    );
  }

  Future<Map<String, dynamic>> linkExpense({
    required String expenseId,
    required String entryId,
  }) {
    return linkExpenses(
      entryId: entryId,
      expenseIds: <String>[expenseId],
    );
  }

  Future<Map<String, dynamic>> linkExpenses({
    required String entryId,
    required List<String> expenseIds,
  }) async {
    final normalizedExpenseIds = expenseIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (normalizedExpenseIds.isEmpty) {
      throw ArgumentError('expenseIds cannot be empty');
    }
    final uri = _u('/link');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'entryId': entryId,
        'expenseIds': normalizedExpenseIds,
      }),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getImportJsonPromptTemplate() async {
    final uri = _u('/import-json/prompt-template');
    final r = await http.get(
      uri,
      headers: await AuthenticatedHttpClient.authorizedHeaders(),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> importJson({
    required Map<String, dynamic> payload,
    Uint8List? invoiceFileBytes,
    String? invoiceFileName,
    Uint8List? jsonFileBytes,
    String? jsonFileName,
  }) async {
    final uri = _u('/import-json');
    final hasMultipart =
        (invoiceFileBytes != null && invoiceFileBytes.isNotEmpty) ||
            (jsonFileBytes != null && jsonFileBytes.isNotEmpty);

    if (!hasMultipart) {
      final r = await AuthenticatedHttpClient.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(payload),
      );
      final out = _decode<Map<String, dynamic>>(
        r,
        url: uri,
        method: 'POST',
        map: (j) =>
            (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
      );
      out['_statusCode'] = r.statusCode;
      return out;
    }

    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers(json: false));
    req.fields['json'] = jsonEncode(payload);

    if (jsonFileBytes != null && jsonFileBytes.isNotEmpty) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'jsonFile',
          jsonFileBytes,
          filename: (jsonFileName == null || jsonFileName.trim().isEmpty)
              ? 'expense-import.json'
              : jsonFileName.trim(),
          contentType: MediaType('application', 'json'),
        ),
      );
    }

    if (invoiceFileBytes != null && invoiceFileBytes.isNotEmpty) {
      final invoiceName =
          (invoiceFileName == null || invoiceFileName.trim().isEmpty)
              ? 'invoice-file'
              : invoiceFileName.trim();
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          invoiceFileBytes,
          filename: invoiceName,
          contentType: _mediaTypeForFileName(invoiceName),
        ),
      );
    }

    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    final out = _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
    out['_statusCode'] = r.statusCode;
    return out;
  }

  Future<Map<String, dynamic>> importJsonBatch({
    required Map<String, dynamic> payload,
    required List<Uint8List> documentFilesBytes,
    required List<String> documentFileNames,
    String? groupId,
  }) async {
    if (documentFilesBytes.isEmpty ||
        documentFilesBytes.length != documentFileNames.length) {
      throw ArgumentError(
        'documentFilesBytes/documentFileNames must be non-empty and have same length',
      );
    }

    return _sendBatchMultipartRequest(
      endpoint: '/import-json-batch',
      documentFilesBytes: documentFilesBytes,
      documentFileNames: documentFileNames,
      groupId: groupId,
      payload: payload,
    );
  }

  Future<Map<String, dynamic>> generateBatchJsonWithAi({
    required List<Uint8List> documentFilesBytes,
    required List<String> documentFileNames,
    String? groupId,
  }) async {
    if (documentFilesBytes.isEmpty ||
        documentFilesBytes.length != documentFileNames.length) {
      throw ArgumentError(
        'documentFilesBytes/documentFileNames must be non-empty and have same length',
      );
    }

    return _sendBatchMultipartRequest(
      endpoint: '/import-json-batch/generate-with-ai',
      documentFilesBytes: documentFilesBytes,
      documentFileNames: documentFileNames,
      groupId: groupId,
    );
  }

  Future<Map<String, dynamic>> startBatchAiImportJob({
    required List<Uint8List> documentFilesBytes,
    required List<String> documentFileNames,
    String? groupId,
    String? currency,
  }) async {
    if (documentFilesBytes.isEmpty ||
        documentFilesBytes.length != documentFileNames.length) {
      throw ArgumentError(
        'documentFilesBytes/documentFileNames must be non-empty and have same length',
      );
    }

    return _sendBatchMultipartRequest(
      endpoint: '/import-json-batch/generate-with-ai/start',
      documentFilesBytes: documentFilesBytes,
      documentFileNames: documentFileNames,
      groupId: groupId,
      extraFields: {
        if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> startBatchExpensePreviewJob({
    required List<Uint8List> documentFilesBytes,
    required List<String> documentFileNames,
    String? groupId,
    String? currency,
  }) async {
    if (documentFilesBytes.isEmpty ||
        documentFilesBytes.length != documentFileNames.length) {
      throw ArgumentError(
        'documentFilesBytes/documentFileNames must be non-empty and have same length',
      );
    }

    return _sendBatchMultipartRequest(
      endpoint: '/import-json-batch/preview/start',
      documentFilesBytes: documentFilesBytes,
      documentFileNames: documentFileNames,
      groupId: groupId,
      extraFields: {
        if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> getBatchAiImportJobStatus(String jobId) async {
    final trimmedJobId = jobId.trim();
    if (trimmedJobId.isEmpty) {
      throw ArgumentError('jobId is required');
    }
    final uri = _u('/import-json-batch/jobs/$trimmedJobId');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getBatchAiImportJobResult(String jobId) async {
    final trimmedJobId = jobId.trim();
    if (trimmedJobId.isEmpty) {
      throw ArgumentError('jobId is required');
    }
    final uri = _u('/import-json-batch/jobs/$trimmedJobId/result');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getBatchExpensePreviewJobStatus(
      String jobId) async {
    final trimmedJobId = jobId.trim();
    if (trimmedJobId.isEmpty) {
      throw ArgumentError('jobId is required');
    }
    final uri = _u('/import-json-batch/preview/jobs/$trimmedJobId');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getBatchExpensePreviewJobResult(
      String jobId) async {
    final trimmedJobId = jobId.trim();
    if (trimmedJobId.isEmpty) {
      throw ArgumentError('jobId is required');
    }
    final uri = _u('/import-json-batch/preview/jobs/$trimmedJobId/result');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> confirmBatchExpenseImports({
    required String groupId,
    required List<Map<String, dynamic>> items,
  }) async {
    final trimmedGroupId = groupId.trim();
    if (trimmedGroupId.isEmpty) {
      throw ArgumentError('groupId is required');
    }
    if (items.isEmpty) {
      throw ArgumentError('items cannot be empty');
    }
    final uri = _u('/import-json-batch/confirm');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'groupId': trimmedGroupId,
        'items': items,
      }),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'POST',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<ExpenseBatchIncidentExport> downloadBatchIncidentExport(
    String batchId,
  ) async {
    final trimmedBatchId = batchId.trim();
    if (trimmedBatchId.isEmpty) {
      throw ArgumentError('batchId is required');
    }
    final encodedBatchId = Uri.encodeComponent(trimmedBatchId);
    final uri = _apiUri('/import-batches/$encodedBatchId/failed-export');
    final r = await AuthenticatedHttpClient.get(
      uri,
      headers: await _headers(json: false),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ExpensesApiException(
        statusCode: r.statusCode,
        message: 'Could not generate incident export.',
        url: uri,
        method: 'GET',
        responseBody: r.body.isEmpty ? null : r.body,
      );
    }
    final contentDisposition =
        r.headers['content-disposition'] ?? r.headers['Content-Disposition'];
    final fileName = _filenameFromContentDisposition(contentDisposition) ??
        'importacion-incidencias-$trimmedBatchId.xlsx';
    return ExpenseBatchIncidentExport(
      bytes: r.bodyBytes,
      fileName: fileName,
      contentType: r.headers['content-type'] ??
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<Map<String, dynamic>> fetchExpense(String id) async {
    final uri = _u('/$id');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> fetchExpenseFile(String id) async {
    final uri = _u('/$id/file');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<List<Map<String, dynamic>>> summary({
    String? groupId,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (groupId != null && groupId.trim().isNotEmpty) {
      params['groupId'] = groupId.trim();
    }
    if (from != null && from.trim().isNotEmpty) {
      params['from'] = from.trim();
    }
    if (to != null && to.trim().isNotEmpty) {
      params['to'] = to.trim();
    }
    final uri = _u('/summary', params.isEmpty ? null : params);
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is Map && j['summary'] is List) {
          return (j['summary'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (j is List) {
          return j
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> summaryTotals({
    required String groupId,
    String? providerId,
    String? clientId,
    String? from,
    String? to,
    String? currency,
  }) async {
    final params = <String, String>{
      'groupId': groupId.trim(),
      if ((providerId ?? '').trim().isNotEmpty)
        'providerId': providerId!.trim(),
      if ((clientId ?? '').trim().isNotEmpty) 'clientId': clientId!.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
    final uri = _u('/summary-totals', params);
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getVatAudit({
    required String groupId,
    String? providerId,
    String? clientId,
    String? from,
    String? to,
    String? currency,
  }) async {
    final params = <String, String>{
      'groupId': groupId.trim(),
      if ((providerId ?? '').trim().isNotEmpty)
        'providerId': providerId!.trim(),
      if ((clientId ?? '').trim().isNotEmpty) 'clientId': clientId!.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
    final uri = _u('/vat-audit', params);
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
    if (kDebugMode) {
      debugPrint(
        '[ExpensesApi] vat-audit status=${r.statusCode} '
        'count=${r.body.length > 300 ? "${r.body.substring(0, 300)}…" : r.body}',
      );
    }
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }

  Future<http.Response> exportVatAuditExcel({
    required String groupId,
    String? providerId,
    String? clientId,
    String? from,
    String? to,
    String? currency,
  }) async {
    final params = <String, String>{
      'groupId': groupId.trim(),
      if ((providerId ?? '').trim().isNotEmpty)
        'providerId': providerId!.trim(),
      if ((clientId ?? '').trim().isNotEmpty) 'clientId': clientId!.trim(),
      if ((from ?? '').trim().isNotEmpty) 'from': from!.trim(),
      if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
      if ((currency ?? '').trim().isNotEmpty) 'currency': currency!.trim(),
    };
    final uri = _u('/vat-audit/export.xlsx', params);
    final response = await AuthenticatedHttpClient.get(uri,
        headers: await _headers(json: false));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode<Map<String, dynamic>>(
        response,
        url: uri,
        method: 'GET',
        map: (j) =>
            (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
      );
    }
    return response;
  }

  Future<Map<String, dynamic>> patchSuspicionReview(
    String expenseId, {
    required String status,
    String? notes,
  }) async {
    final uri = _u('/$expenseId/suspicion-review');
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }
    final r = await AuthenticatedHttpClient.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'PATCH',
      map: (j) =>
          (j is Map) ? Map<String, dynamic>.from(j) : <String, dynamic>{},
    );
  }
}
