import 'dart:convert';

import 'package:hexora/models/invoice/invoice_line.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/invoicing/invoice_lines_api.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_models.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_normalizer.dart';
import 'package:http/http.dart' as http;

typedef OcrTelemetryHook = void Function(
  String event,
  Map<String, dynamic> payload,
);

typedef CreateInvoiceLineFn = Future<InvoiceLine> Function(
  String invoiceId,
  InvoiceLine line,
);

class InvoiceLinesOcrService {
  InvoiceLinesOcrService({
    InvoiceLinesApi? linesApi,
    http.Client? client,
    OcrTelemetryHook? telemetry,
  })  : _linesApi = linesApi ?? InvoiceLinesApi(),
        _client = client ?? http.Client(),
        _telemetry = telemetry;

  final InvoiceLinesApi _linesApi;
  final http.Client _client;
  final OcrTelemetryHook? _telemetry;

  Uri _extractUri(String invoiceId) => Uri.parse(
        '${ApiConstants.baseUrl}/invoices/$invoiceId/lines/extract-image',
      );

  Future<InvoiceAiChatResponse> chatAboutInvoice({
    required String invoiceId,
    required String message,
    required List<OcrExtractedLineDraft> draftLines,
    required List<Map<String, String>> history,
    required String locale,
    OcrImageFile? file,
  }) async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final authorization = headers['Authorization'];
    if (authorization == null || authorization.isEmpty) {
      throw const OcrExtractionException(
        userMessage: 'Please sign in again.',
        debugMessage: 'Missing access token',
      );
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/invoices/$invoiceId/lines/ai-chat'),
    );
    request.headers['Authorization'] = authorization;
    request.fields['message'] = message;
    request.fields['locale'] = locale;
    request.fields['draftLines'] =
        jsonEncode(draftLines.map((e) => e.toJson()).toList());
    request.fields['history'] = jsonEncode(history);
    if (file != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        file.bytes,
        filename: file.fileName,
      ));
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw OcrExtractionException(
        statusCode: response.statusCode,
        userMessage: message ?? 'Could not prepare the invoice draft.',
        debugMessage: message ?? response.reasonPhrase ?? 'Request failed',
      );
    }
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    final rawLines = data['draftLines'];
    if (rawLines is! List) {
      throw const OcrExtractionException(
        userMessage: 'The AI response could not be read.',
        debugMessage: 'Missing draftLines',
      );
    }
    return InvoiceAiChatResponse(
      reply: data['reply']?.toString() ?? '',
      requiresSingleInvoice: data['requiresSingleInvoice'] == true,
      draftLines: [
        for (var i = 0; i < rawLines.length; i++)
          normalizeExtractedLine(rawLines[i], i),
      ],
    );
  }

  Future<OcrExtractResponse> extractInvoiceLinesFromImage({
    required String invoiceId,
    required OcrImageFile file,
    double? defaultTaxRate,
  }) async {
    _telemetry?.call('extraction_started', {
      'invoiceId': invoiceId,
      'fileName': file.fileName,
      if (defaultTaxRate != null) 'defaultTaxRate': defaultTaxRate,
    });

    try {
      final authHeaders = await AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: false,
      );
      final auth = authHeaders['Authorization'];
      if (auth == null || auth.isEmpty) {
        throw const OcrExtractionException(
          userMessage: 'No se pudo procesar la imagen.',
          debugMessage: 'Missing access token',
        );
      }

      final req = http.MultipartRequest('POST', _extractUri(invoiceId));
      req.headers['Authorization'] = auth;
      req.fields['method'] = 'openai';
      if (defaultTaxRate != null) {
        req.fields['defaultTaxRate'] = defaultTaxRate.toString();
      }
      req.files.add(http.MultipartFile.fromBytes(
        'image',
        file.bytes,
        filename: file.fileName,
      ));

      final streamed = await _client.send(req);
      final response = await http.Response.fromStream(streamed);

      dynamic decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = response.body;
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String backendMessage = response.reasonPhrase ?? 'Request failed';
        if (decoded is Map && decoded['message'] != null) {
          backendMessage = decoded['message'].toString();
        } else if (decoded is Map && decoded['error'] != null) {
          backendMessage = decoded['error'].toString();
        } else if (decoded is String && decoded.trim().isNotEmpty) {
          backendMessage = decoded.trim();
        }

        final normalizedMessage = backendMessage.toLowerCase();
        final errorCode = decoded is Map
            ? (decoded['code'] ?? decoded['errorCode'])?.toString().trim()
            : null;
        String userMessage;
        if (response.statusCode == 404 && errorCode == 'INVOICE_NOT_FOUND') {
          userMessage = 'Factura no encontrada.';
        } else if (response.statusCode == 400 ||
            errorCode == 'INVALID_IMAGE' ||
            errorCode == 'UNSUPPORTED_IMAGE') {
          userMessage = 'No se pudo procesar la imagen.';
        } else if (response.statusCode == 429) {
          userMessage =
              'Demasiadas solicitudes. Espera un momento y reintenta.';
        } else if (response.statusCode == 404 ||
            response.statusCode == 501 ||
            response.statusCode == 503 ||
            response.statusCode >= 500) {
          userMessage =
              'El servicio de extracción no está disponible. Inténtalo de nuevo más tarde.';
        } else if (normalizedMessage.contains('invalid invoiceid') ||
            normalizedMessage.contains('image file is required')) {
          userMessage = 'No se pudo procesar la imagen.';
        } else {
          userMessage = 'No se pudo procesar la imagen.';
        }

        throw OcrExtractionException(
          statusCode: response.statusCode,
          userMessage: userMessage,
          debugMessage: backendMessage,
        );
      }

      final normalized = normalizeExtractResponse(decoded);
      _telemetry?.call('extraction_completed', {
        'invoiceId': invoiceId,
        'lineCount': normalized.lineCount,
        'confidence': normalized.confidence,
      });
      return normalized;
    } on OcrExtractionException catch (e) {
      _telemetry?.call('extraction_failed', {
        'invoiceId': invoiceId,
        'statusCode': e.statusCode,
        'error': e.debugMessage,
      });
      rethrow;
    } catch (e) {
      _telemetry?.call('extraction_failed', {
        'invoiceId': invoiceId,
        'error': e.toString(),
      });
      throw OcrExtractionException(
        userMessage: 'No se pudo procesar la imagen.',
        debugMessage: e.toString(),
      );
    }
  }

  Future<InvoiceLine> createInvoiceLine(
    String invoiceId,
    OcrExtractedLineDraft line,
  ) {
    final payload = InvoiceLine(
      invoiceId: invoiceId,
      position: line.position,
      description: line.description,
      quantity: line.quantity,
      unitPrice: line.unitPrice,
      taxRate: line.taxRate,
      lineSubtotal: line.lineSubtotal,
      lineTax: line.lineTax,
      lineTotal: line.lineTotal,
      conceptTitle: line.conceptTitle,
      conceptItems: line.conceptItems,
      serviceDate: line.serviceDate,
      isCompositeConcept: line.isCompositeConcept,
      parseMethod: line.parseMethod,
    );
    return _linesApi.create(invoiceId, payload);
  }

  Future<OcrBulkSaveResult> createInvoiceLinesBulk(
    String invoiceId,
    List<OcrExtractedLineDraft> draftLines, {
    CreateInvoiceLineFn? createFn,
  }) async {
    final creator = createFn ??
        (String id, InvoiceLine line) async {
          return _linesApi.create(id, line);
        };

    _telemetry?.call('save_started', {
      'invoiceId': invoiceId,
      'lineCount': draftLines.length,
    });

    final sorted = List<OcrExtractedLineDraft>.from(draftLines)
      ..sort((a, b) => a.position.compareTo(b.position));

    final success = <OcrExtractedLineDraft>[];
    final failed = <OcrSaveFailure>[];

    for (var i = 0; i < sorted.length; i++) {
      final line = normalizeExtractedLine(sorted[i].toJson(), i);

      final validation = _validateLine(line);
      if (validation != null) {
        failed.add(OcrSaveFailure(index: i, line: line, reason: validation));
        continue;
      }

      try {
        final payload = InvoiceLine(
          invoiceId: invoiceId,
          position: line.position,
          description: line.description,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          taxRate: line.taxRate,
          lineSubtotal: line.lineSubtotal,
          lineTax: line.lineTax,
          lineTotal: line.lineTotal,
          conceptTitle: line.conceptTitle,
          conceptItems: line.conceptItems,
          serviceDate: line.serviceDate,
          isCompositeConcept: line.isCompositeConcept,
          parseMethod: line.parseMethod,
        );
        await creator(invoiceId, payload);
        success.add(line);
      } catch (e) {
        failed.add(OcrSaveFailure(
          index: i,
          line: line,
          reason: e.toString(),
        ));
      }
    }

    final result = OcrBulkSaveResult(success: success, failed: failed);
    _telemetry?.call('save_completed', {
      'invoiceId': invoiceId,
      'savedCount': result.savedCount,
      'failedCount': result.failedCount,
    });
    return result;
  }

  String? _validateLine(OcrExtractedLineDraft line) {
    if (line.description.trim().isEmpty) return 'Description is required';
    if (line.quantity <= 0) return 'Quantity must be greater than 0';
    if (line.unitPrice < 0) return 'Unit price must be >= 0';
    if (line.taxRate < 0) return 'Tax rate must be >= 0';
    return null;
  }
}
