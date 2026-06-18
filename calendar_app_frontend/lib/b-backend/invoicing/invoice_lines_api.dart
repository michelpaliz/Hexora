import 'dart:convert';
import 'dart:typed_data';

import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class InvoiceLineEvidenceException implements Exception {
  const InvoiceLineEvidenceException({
    required this.userMessage,
    required this.debugMessage,
    this.statusCode,
  });

  final String userMessage;
  final String debugMessage;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'Invoice line evidence error$code: $debugMessage';
  }
}

class InvoiceLineEvidenceFile {
  const InvoiceLineEvidenceFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get sizeBytes => bytes.lengthInBytes;
}

class InvoiceLineEvidenceUploadSas {
  const InvoiceLineEvidenceUploadSas({
    required this.uploadUrl,
    required this.blobName,
    required this.blobUrl,
    required this.expiresOn,
  });

  final String uploadUrl;
  final String blobName;
  final String? blobUrl;
  final String? expiresOn;
}

class InvoiceLineEvidenceReadUrl {
  const InvoiceLineEvidenceReadUrl({
    required this.public,
    required this.url,
    required this.blobName,
  });

  final bool public;
  final String url;
  final String blobName;
}

class InvoiceLineEvidenceAttachResult {
  const InvoiceLineEvidenceAttachResult({
    required this.line,
    required this.evidenceBlobName,
    required this.evidenceUrl,
  });

  final InvoiceLine line;
  final String evidenceBlobName;
  final String? evidenceUrl;
}

class InvoiceLinesJsonImportResult {
  const InvoiceLinesJsonImportResult({
    required this.importedCount,
    required this.raw,
  });

  final int importedCount;
  final Map<String, dynamic> raw;
}

class InvoiceLinesJsonPromptTemplate {
  const InvoiceLinesJsonPromptTemplate({
    required this.prompt,
    required this.raw,
  });

  final String prompt;
  final Map<String, dynamic> raw;
}

class InvoiceLinesJsonImportException implements Exception {
  const InvoiceLinesJsonImportException({
    required this.userMessage,
    required this.debugMessage,
    this.statusCode,
  });

  final String userMessage;
  final String debugMessage;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'Invoice lines JSON import error$code: $debugMessage';
  }
}

class InvoiceLinesApi {
  final String _base = '${ApiConstants.baseUrl}/invoices';
  static const int maxEvidenceFileBytes = 10 * 1024 * 1024;
  static const Set<String> allowedEvidenceMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  };

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json; charset=UTF-8',
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
    final r = await AuthenticatedHttpClient.get(_u(invoiceId),
        headers: _jsonHeaders());
    return _decode<List<InvoiceLine>>(r, (j) {
      if (j is! List) throw Exception('Unexpected invoice lines payload');
      return j
          .whereType<Map<String, dynamic>>()
          .map(InvoiceLine.fromJson)
          .toList();
    });
  }

  Future<InvoiceLine> create(String invoiceId, InvoiceLine line) async {
    final body = line.toJson()
      ..remove('id')
      ..remove('invoiceId');
    final r = await AuthenticatedHttpClient.post(
      _u(invoiceId),
      headers: _jsonHeaders(),
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
    final r = await AuthenticatedHttpClient.patch(
      _u(invoiceId, '/$lineId'),
      headers: _jsonHeaders(),
      body: jsonEncode(patch),
    );
    return _decode<InvoiceLine>(r, (j) {
      if (j is Map<String, dynamic>) return InvoiceLine.fromJson(j);
      throw Exception('Unexpected invoice line payload');
    });
  }

  Future<void> delete(String invoiceId, String lineId) async {
    final r = await AuthenticatedHttpClient.delete(
      _u(invoiceId, '/$lineId'),
      headers: _jsonHeaders(),
    );
    _decode<void>(r, (_) {});
  }

  InvoiceLineEvidenceException _evidenceErrorFromResponse(http.Response r) {
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }

    String backendMessage = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      backendMessage = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      backendMessage = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      backendMessage = body.trim();
    }

    final status = r.statusCode;
    String userMessage;
    if (status == 404) {
      userMessage = 'La linea o factura no existe.';
    } else if (status == 400) {
      userMessage = 'No se pudo adjuntar evidencia.';
    } else if (status >= 500) {
      userMessage = 'Error al procesar la evidencia. Intenta de nuevo.';
    } else {
      userMessage = 'No se pudo adjuntar evidencia.';
    }
    return InvoiceLineEvidenceException(
      statusCode: status,
      userMessage: userMessage,
      debugMessage: backendMessage,
    );
  }

  void _validateEvidenceInput({
    required String invoiceId,
    required String lineId,
    required InvoiceLineEvidenceFile file,
  }) {
    if (invoiceId.trim().isEmpty || lineId.trim().isEmpty) {
      throw const InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage: 'Missing invoiceId or lineId',
      );
    }
    if (!allowedEvidenceMimeTypes.contains(file.mimeType)) {
      throw InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage: 'Unsupported mimeType: ${file.mimeType}',
      );
    }
    if (file.sizeBytes > maxEvidenceFileBytes) {
      throw InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage:
            'File exceeds max size ($maxEvidenceFileBytes): ${file.sizeBytes}',
      );
    }
  }

  Future<InvoiceLineEvidenceUploadSas> getLineEvidenceUploadSas(
    String invoiceId,
    String lineId,
    String mimeType, {
    String strategy = 'versioned',
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u(invoiceId, '/$lineId/evidence/upload-sas'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'mimeType': mimeType,
        if (strategy.trim().isNotEmpty) 'strategy': strategy,
      }),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _evidenceErrorFromResponse(r);
    }
    dynamic j;
    try {
      j = jsonDecode(r.body);
    } catch (_) {
      j = null;
    }
    if (j is! Map<String, dynamic>) {
      throw const InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage: 'Unexpected upload SAS payload',
      );
    }
    return InvoiceLineEvidenceUploadSas(
      uploadUrl: (j['uploadUrl'] ?? '').toString(),
      blobName: (j['blobName'] ?? '').toString(),
      blobUrl: j['blobUrl']?.toString(),
      expiresOn: j['expiresOn']?.toString(),
    );
  }

  Future<void> uploadEvidenceFile(
    String uploadUrl,
    InvoiceLineEvidenceFile file,
  ) async {
    if (uploadUrl.trim().isEmpty) {
      throw const InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage: 'Missing uploadUrl',
      );
    }
    final r = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': file.mimeType,
      },
      body: file.bytes,
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _evidenceErrorFromResponse(r);
    }
  }

  Future<InvoiceLineEvidenceAttachResult> setLineEvidence(
    String invoiceId,
    String lineId,
    String blobName,
  ) async {
    final r = await AuthenticatedHttpClient.put(
      _u(invoiceId, '/$lineId/evidence'),
      headers: _jsonHeaders(),
      body: jsonEncode({'blobName': blobName}),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _evidenceErrorFromResponse(r);
    }
    dynamic j;
    try {
      j = jsonDecode(r.body);
    } catch (_) {
      j = null;
    }
    if (j is! Map<String, dynamic>) {
      throw const InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage: 'Unexpected set evidence payload',
      );
    }
    final lineRaw = j['line'];
    final updatedLine = lineRaw is Map<String, dynamic>
        ? InvoiceLine.fromJson(lineRaw)
        : InvoiceLine(
            id: lineId,
            invoiceId: invoiceId,
            position: 0,
            description: '',
            unitPrice: 0,
            evidenceBlobName: (j['evidenceBlobName'] ?? blobName).toString(),
          );
    return InvoiceLineEvidenceAttachResult(
      line: updatedLine,
      evidenceBlobName: (j['evidenceBlobName'] ?? blobName).toString(),
      evidenceUrl: j['evidenceUrl']?.toString(),
    );
  }

  Future<InvoiceLineEvidenceReadUrl> getLineEvidenceReadUrl(
    String invoiceId,
    String lineId, {
    String? blobName,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u(
        invoiceId,
        '/$lineId/evidence/read-sas',
        blobName == null || blobName.trim().isEmpty
            ? null
            : {'blobName': blobName},
      ),
      headers: _jsonHeaders(),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _evidenceErrorFromResponse(r);
    }
    dynamic j;
    try {
      j = jsonDecode(r.body);
    } catch (_) {
      j = null;
    }
    if (j is! Map<String, dynamic>) {
      throw const InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage: 'Unexpected read SAS payload',
      );
    }
    return InvoiceLineEvidenceReadUrl(
      public: j['public'] == true,
      url: (j['url'] ?? '').toString(),
      blobName: (j['blobName'] ?? '').toString(),
    );
  }

  Future<bool> deleteLineEvidence(
    String invoiceId,
    String lineId,
  ) async {
    final r = await AuthenticatedHttpClient.delete(
      _u(invoiceId, '/$lineId/evidence'),
      headers: _jsonHeaders(),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _evidenceErrorFromResponse(r);
    }
    dynamic j;
    try {
      j = jsonDecode(r.body);
    } catch (_) {
      j = null;
    }
    if (j is! Map<String, dynamic>) return true;
    return j['deleted'] == true;
  }

  Future<InvoiceLineEvidenceAttachResult> attachEvidenceToLine({
    required String invoiceId,
    required String lineId,
    required InvoiceLineEvidenceFile file,
    String strategy = 'versioned',
  }) async {
    _validateEvidenceInput(
      invoiceId: invoiceId,
      lineId: lineId,
      file: file,
    );
    final sas = await getLineEvidenceUploadSas(
      invoiceId,
      lineId,
      file.mimeType,
      strategy: strategy,
    );
    if (sas.uploadUrl.trim().isEmpty || sas.blobName.trim().isEmpty) {
      throw const InvoiceLineEvidenceException(
        userMessage: 'No se pudo adjuntar evidencia.',
        debugMessage: 'Invalid upload SAS response',
      );
    }
    await uploadEvidenceFile(sas.uploadUrl, file);
    return setLineEvidence(invoiceId, lineId, sas.blobName);
  }

  InvoiceLinesJsonImportException _jsonImportErrorFromResponse(
      http.Response r) {
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }

    String backendMessage = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      backendMessage = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      backendMessage = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      backendMessage = body.trim();
    }

    final status = r.statusCode;
    String userMessage;
    if (status == 404) {
      userMessage = 'Factura no encontrada.';
    } else if (status == 409) {
      userMessage = 'Line position already exists';
    } else if (status == 400) {
      userMessage = backendMessage.trim().isEmpty
          ? 'No se pudo importar el JSON.'
          : backendMessage;
    } else {
      userMessage = 'No se pudo importar el JSON.';
    }
    return InvoiceLinesJsonImportException(
      statusCode: status,
      userMessage: userMessage,
      debugMessage: backendMessage,
    );
  }

  InvoiceLinesJsonImportResult _parseJsonImportResult(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      throw const InvoiceLinesJsonImportException(
        userMessage: 'No se pudo importar el JSON.',
        debugMessage: 'Unexpected import-json payload',
      );
    }
    int importedCount = 0;
    final candidates = <dynamic>[
      payload['importedCount'],
      payload['lineCount'],
      payload['createdCount'],
      payload['count'],
    ];
    for (final raw in candidates) {
      if (raw is num) {
        importedCount = raw.toInt();
        break;
      }
      if (raw is String) {
        final parsed = int.tryParse(raw.trim());
        if (parsed != null) {
          importedCount = parsed;
          break;
        }
      }
    }
    return InvoiceLinesJsonImportResult(
      importedCount: importedCount,
      raw: payload,
    );
  }

  Future<InvoiceLinesJsonImportResult> importLinesFromJsonBody(
    String invoiceId, {
    required Map<String, dynamic> payload,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u(invoiceId, '/import-json'),
      headers: _jsonHeaders(),
      body: jsonEncode(payload),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _jsonImportErrorFromResponse(r);
    }
    dynamic body;
    if (r.body.isNotEmpty) {
      body = jsonDecode(r.body);
    }
    return _parseJsonImportResult(body);
  }

  Future<InvoiceLinesJsonImportResult> importLinesFromJsonFile(
    String invoiceId, {
    required Uint8List bytes,
    required String fileName,
    bool overwrite = false,
    double defaultTaxRate = 21,
  }) async {
    final req = http.MultipartRequest('POST', _u(invoiceId, '/import-json'));
    req.headers.addAll(
      await AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: false,
      ),
    );
    req.fields['overwrite'] = overwrite ? 'true' : 'false';
    req.fields['defaultTaxRate'] = defaultTaxRate.toString();
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    ));

    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _jsonImportErrorFromResponse(r);
    }
    dynamic body;
    if (r.body.isNotEmpty) {
      body = jsonDecode(r.body);
    }
    return _parseJsonImportResult(body);
  }

  Future<InvoiceLinesJsonPromptTemplate> getImportJsonPromptTemplate(
    String invoiceId,
  ) async {
    final r = await AuthenticatedHttpClient.get(
      _u(invoiceId, '/import-json/prompt-template'),
      headers: _jsonHeaders(),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _jsonImportErrorFromResponse(r);
    }
    dynamic body;
    if (r.body.isNotEmpty) {
      body = jsonDecode(r.body);
    }
    if (body is! Map<String, dynamic>) {
      throw const InvoiceLinesJsonImportException(
        userMessage: 'No se pudo obtener la plantilla.',
        debugMessage: 'Unexpected prompt-template payload',
      );
    }
    final prompt = (body['promptTemplate'] ??
            body['prompt'] ??
            body['template'] ??
            body['text'] ??
            '')
        .toString();
    return InvoiceLinesJsonPromptTemplate(
      prompt: prompt,
      raw: body,
    );
  }
}
