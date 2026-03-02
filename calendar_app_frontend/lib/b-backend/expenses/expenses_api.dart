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

class ExpensesApi {
  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/expenses'
      : '${ApiConstants.baseUrl}/api/expenses';

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  MediaType _mediaTypeForFileName(String? fileName) {
    final lower = (fileName ?? '').toLowerCase().trim();
    if (lower.endsWith('.pdf')) {
      return MediaType('application', 'pdf');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
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

  static const List<String> _batchFileFieldCandidates = <String>[
    'files',
    'documents',
    'invoiceFiles',
  ];

  bool _shouldRetryBatchWithAlternateField(ExpensesApiException e) {
    final lowerMsg = e.message.toLowerCase();
    final lowerBody = (e.responseBody ?? '').toLowerCase();
    final joined = '$lowerMsg\n$lowerBody';
    return joined.contains('failed to extract one or more files') ||
        joined.contains('unsupported mime type') ||
        joined.contains("application/octet-stream") ||
        joined.contains('no files') ||
        joined.contains('file is required') ||
        joined.contains('missing file');
  }

  Future<Map<String, dynamic>> _sendBatchMultipartRequest({
    required String endpoint,
    required List<Uint8List> documentFilesBytes,
    required List<String> documentFileNames,
    required String fileFieldName,
    String? groupId,
    Map<String, dynamic>? payload,
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

    for (var i = 0; i < documentFilesBytes.length; i++) {
      final bytes = documentFilesBytes[i];
      final name = documentFileNames[i].trim().isEmpty
          ? 'document-$i'
          : documentFileNames[i].trim();
      req.files.add(
        http.MultipartFile.fromBytes(
          fileFieldName,
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

  Future<void> linkExpense({
    required String expenseId,
    required String entryId,
  }) async {
    final uri = _u('/link');
    final r = await AuthenticatedHttpClient.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'expenseId': expenseId,
        'entryId': entryId,
      }),
    );
    _decode<void>(
      r,
      url: uri,
      method: 'POST',
      map: (_) {},
    );
  }

  Future<Map<String, dynamic>> getImportJsonPromptTemplate() async {
    final uri = _u('/import-json/prompt-template');
    final r = await AuthenticatedHttpClient.get(uri, headers: await _headers());
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

    ExpensesApiException? lastException;
    for (final field in _batchFileFieldCandidates) {
      try {
        return await _sendBatchMultipartRequest(
          endpoint: '/import-json-batch',
          documentFilesBytes: documentFilesBytes,
          documentFileNames: documentFileNames,
          fileFieldName: field,
          groupId: groupId,
          payload: payload,
        );
      } on ExpensesApiException catch (e) {
        lastException = e;
        if (!_shouldRetryBatchWithAlternateField(e) ||
            field == _batchFileFieldCandidates.last) {
          rethrow;
        }
        if (kDebugMode) {
          debugPrint(
            'Retrying import-json-batch with alternate file field after failure on "$field".',
          );
        }
      }
    }
    throw lastException!;
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

    ExpensesApiException? lastException;
    for (final field in _batchFileFieldCandidates) {
      try {
        return await _sendBatchMultipartRequest(
          endpoint: '/import-json-batch/generate-with-ai',
          documentFilesBytes: documentFilesBytes,
          documentFileNames: documentFileNames,
          fileFieldName: field,
          groupId: groupId,
        );
      } on ExpensesApiException catch (e) {
        lastException = e;
        if (!_shouldRetryBatchWithAlternateField(e) ||
            field == _batchFileFieldCandidates.last) {
          rethrow;
        }
        if (kDebugMode) {
          debugPrint(
            'Retrying generate-with-ai with alternate file field after failure on "$field".',
          );
        }
      }
    }
    throw lastException!;
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
}
