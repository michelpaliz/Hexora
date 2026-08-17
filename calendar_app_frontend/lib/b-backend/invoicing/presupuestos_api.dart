import 'dart:convert';

import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class PresupuestosApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  PresupuestosApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'Exception: $message';
}

class CreateAdvanceInvoiceConfig {
  final double percent;
  final double? projectBaseAmount;
  final double? taxRate;
  final String? description;

  const CreateAdvanceInvoiceConfig({
    required this.percent,
    this.projectBaseAmount,
    this.taxRate,
    this.description,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'percent': percent,
        if (projectBaseAmount != null) 'projectBaseAmount': projectBaseAmount,
        if (taxRate != null) 'taxRate': taxRate,
        if ((description ?? '').trim().isNotEmpty) 'description': description,
      };
}

class CreateAdvanceInvoiceFromPresupuestoRequest {
  final CreateAdvanceInvoiceConfig advanceConfig;
  final String? notes;

  const CreateAdvanceInvoiceFromPresupuestoRequest({
    required this.advanceConfig,
    this.notes,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'advanceConfig': advanceConfig.toJson(),
        if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class CreateFinalInvoiceFromPresupuestoRequest {
  final String? advanceInvoiceId;
  final String? notes;

  const CreateFinalInvoiceFromPresupuestoRequest({
    this.advanceInvoiceId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    final trimmed = advanceInvoiceId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      payload['advanceInvoiceId'] = trimmed;
    }
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) {
      payload['notes'] = trimmedNotes;
    }
    return payload;
  }
}

class PresupuestoCreateInvoiceResponse {
  final bool ok;
  final String? invoiceType;
  final String? presupuestoId;
  final String? invoiceId;
  final Map<String, dynamic>? invoice;
  final Map<String, dynamic> raw;

  const PresupuestoCreateInvoiceResponse({
    required this.ok,
    this.invoiceType,
    this.presupuestoId,
    this.invoiceId,
    this.invoice,
    required this.raw,
  });

  factory PresupuestoCreateInvoiceResponse.fromJson(Map<String, dynamic> json) {
    final invoice = json['invoice'];
    return PresupuestoCreateInvoiceResponse(
      ok: json['ok'] == true,
      invoiceType: json['invoiceType']?.toString(),
      presupuestoId: json['presupuestoId']?.toString(),
      invoiceId: json['invoiceId']?.toString(),
      invoice: invoice is Map ? Map<String, dynamic>.from(invoice) : null,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class PresupuestosApi {
  final String _base = '${ApiConstants.baseUrl}/presupuestos';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Uri _u([String path = '']) => Uri.parse('$_base$path');

  Uri buildCreateAdvanceInvoiceUri(String presupuestoId) =>
      _u('/${presupuestoId.trim()}/create-advance-invoice');

  Uri buildCreateDraftUri() => _u();

  Uri buildCreateDocumentDraftUri() => _u('/documents');

  Uri buildListDocumentsByGroupUri(String groupId, {String? search}) {
    final query = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    return query.isEmpty
        ? _u('/documents/group/${groupId.trim()}')
        : _u(
            '/documents/group/${groupId.trim()}?${Uri(queryParameters: query).query}',
          );
  }

  Uri buildDocumentIssueUri(String presupuestoId) =>
      _u('/${presupuestoId.trim()}/issue');

  Uri buildCreateDocumentFromDefaultUri({
    required String key,
    required String groupId,
  }) =>
      _u(
        '/documents/defaults/${Uri.encodeComponent(key)}/group/${groupId.trim()}',
      );

  Uri buildCreateFinalInvoiceUri(String presupuestoId) =>
      _u('/${presupuestoId.trim()}/create-final-invoice');

  Uri buildListByGroupUri(
    String groupId, {
    String? clientId,
    String? sortBy,
    String? sortDir,
    int? limit,
  }) {
    final query = <String, String>{
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
      if (sortBy != null && sortBy.trim().isNotEmpty) 'sortBy': sortBy.trim(),
      if (sortDir != null && sortDir.trim().isNotEmpty)
        'sortDir': sortDir.trim(),
      if (limit != null && limit > 0) 'limit': limit.toString(),
    };
    return query.isEmpty
        ? _u('/group/${groupId.trim()}')
        : _u('/group/${groupId.trim()}?${Uri(queryParameters: query).query}');
  }

  dynamic _tryDecodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String _resolveErrorMessage(http.Response r, dynamic body) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }
    return r.reasonPhrase ?? 'Request failed';
  }

  String? _resolveErrorCode(dynamic body) {
    if (body is Map && body['code'] != null) {
      final code = body['code'].toString().trim();
      return code.isEmpty ? null : code;
    }
    return null;
  }

  Map<String, dynamic>? _resolveErrorDetails(dynamic body) {
    if (body is Map && body['details'] is Map) {
      return Map<String, dynamic>.from(body['details'] as Map);
    }
    return null;
  }

  Map<String, dynamic> _decodeMap(http.Response r) {
    final body = _tryDecodeBody(r.body);
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) {
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected presupuesto payload');
    }
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  List<Map<String, dynamic>> _decodeList(http.Response r) {
    final body = _tryDecodeBody(r.body);
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
      if (body is Map && body['items'] is List) {
        return (body['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
      throw Exception('Unexpected presupuesto list payload');
    }
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> createDraft({
    required String groupId,
    String? clientId,
    String? clientName,
    String? addressStreet,
    String? addressCity,
    String? addressPostalCode,
    Map<String, dynamic>? clientSnapshot,
    List<Map<String, dynamic>>? lines,
    List<Map<String, dynamic>>? blocks,
  }) async {
    final payload = <String, dynamic>{
      'groupId': groupId,
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
      if (clientName != null && clientName.trim().isNotEmpty)
        'clientName': clientName.trim(),
      if (addressStreet != null && addressStreet.trim().isNotEmpty)
        'addressStreet': addressStreet.trim(),
      if (addressCity != null && addressCity.trim().isNotEmpty)
        'addressCity': addressCity.trim(),
      if (addressPostalCode != null && addressPostalCode.trim().isNotEmpty)
        'addressPostalCode': addressPostalCode.trim(),
      if (clientSnapshot != null) 'clientSnapshot': clientSnapshot,
      if (lines != null && lines.isNotEmpty) 'lines': lines,
      if (blocks != null && blocks.isNotEmpty) 'blocks': blocks,
    };
    final r = await AuthenticatedHttpClient.post(
      buildCreateDraftUri(),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> updateDraft({
    required String id,
    String? clientId,
    String? clientName,
    String? addressStreet,
    String? addressCity,
    String? addressPostalCode,
    Map<String, dynamic>? clientSnapshot,
    String? issueDate,
    String? notes,
    String? currency,
    List<Map<String, dynamic>>? lines,
    List<Map<String, dynamic>>? blocks,
    Map<String, dynamic>? totals,
  }) async {
    final payload = <String, dynamic>{
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
      if (clientName != null && clientName.trim().isNotEmpty)
        'clientName': clientName.trim(),
      if (addressStreet != null && addressStreet.trim().isNotEmpty)
        'addressStreet': addressStreet.trim(),
      if (addressCity != null && addressCity.trim().isNotEmpty)
        'addressCity': addressCity.trim(),
      if (addressPostalCode != null && addressPostalCode.trim().isNotEmpty)
        'addressPostalCode': addressPostalCode.trim(),
      if (clientSnapshot != null) 'clientSnapshot': clientSnapshot,
      if (issueDate != null && issueDate.trim().isNotEmpty)
        'issueDate': issueDate.trim(),
      if (notes != null) 'notes': notes,
      if (currency != null && currency.trim().isNotEmpty)
        'currency': currency.trim(),
      if (lines != null) 'lines': lines,
      if (blocks != null) 'blocks': blocks,
      if (totals != null) 'totals': totals,
    };
    final r = await AuthenticatedHttpClient.patch(
      _u('/$id/draft'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> updateIssued({
    required String id,
    String? clientId,
    String? clientName,
    String? addressStreet,
    String? addressCity,
    String? addressPostalCode,
    List<Map<String, dynamic>>? lines,
    List<Map<String, dynamic>>? blocks,
    String? issueDate,
    String? notes,
    String? currency,
    Map<String, dynamic>? clientSnapshot,
    Map<String, dynamic>? issuerSnapshot,
    Map<String, dynamic>? totals,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
      if (clientName != null && clientName.trim().isNotEmpty)
        'clientName': clientName.trim(),
      if (addressStreet != null && addressStreet.trim().isNotEmpty)
        'addressStreet': addressStreet.trim(),
      if (addressCity != null && addressCity.trim().isNotEmpty)
        'addressCity': addressCity.trim(),
      if (addressPostalCode != null && addressPostalCode.trim().isNotEmpty)
        'addressPostalCode': addressPostalCode.trim(),
      if (lines != null) 'lines': lines,
      if (blocks != null) 'blocks': blocks,
      if (issueDate != null && issueDate.trim().isNotEmpty)
        'issueDate': issueDate.trim(),
      if (notes != null) 'notes': notes,
      if (currency != null && currency.trim().isNotEmpty)
        'currency': currency.trim(),
      if (clientSnapshot != null) 'clientSnapshot': clientSnapshot,
      if (issuerSnapshot != null) 'issuerSnapshot': issuerSnapshot,
      if (totals != null) 'totals': totals,
      'reason': reason.trim(),
    };
    final r = await AuthenticatedHttpClient.patch(
      _u('/$id/issued'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> issue(String id) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/issue'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<void> remove(String id) async {
    final r = await AuthenticatedHttpClient.delete(
      _u('/$id'),
      headers: _headers(),
    );
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) return;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> convertToInvoice(String id) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/convert-to-invoice'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<PresupuestoCreateInvoiceResponse> createAdvanceInvoiceFromPresupuesto(
    String presupuestoId, {
    required CreateAdvanceInvoiceFromPresupuestoRequest payload,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      buildCreateAdvanceInvoiceUri(presupuestoId),
      headers: _headers(),
      body: jsonEncode(payload.toJson()),
    );
    return PresupuestoCreateInvoiceResponse.fromJson(_decodeMap(r));
  }

  Future<PresupuestoCreateInvoiceResponse> createFinalInvoiceFromPresupuesto(
    String presupuestoId, {
    CreateFinalInvoiceFromPresupuestoRequest payload =
        const CreateFinalInvoiceFromPresupuestoRequest(),
  }) async {
    final r = await AuthenticatedHttpClient.post(
      buildCreateFinalInvoiceUri(presupuestoId),
      headers: _headers(),
      body: jsonEncode(payload.toJson()),
    );
    return PresupuestoCreateInvoiceResponse.fromJson(_decodeMap(r));
  }

  Future<List<Map<String, dynamic>>> listByGroup({
    required String groupId,
    String? clientId,
    String? sortBy,
    String? sortDir,
    int? limit,
  }) async {
    final uri = buildListByGroupUri(
      groupId,
      clientId: clientId,
      sortBy: sortBy,
      sortDir: sortDir,
      limit: limit,
    );
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decodeList(r);
  }

  Future<http.Response> previewPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf/preview'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to preview presupuesto PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> downloadPdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/pdf'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to download presupuesto PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> listTemplatesByGroup(String groupId) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/templates/group/${groupId.trim()}'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> listDefaultTemplates() async {
    final r = await AuthenticatedHttpClient.get(
      _u('/templates/defaults'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> createTemplateFromDefault({
    required String key,
    required String groupId,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/templates/defaults/${Uri.encodeComponent(key)}/group/${groupId.trim()}'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> createDocumentDraft({
    required String groupId,
    required Map<String, dynamic> content,
  }) async {
    final payload = buildDocumentDraftPayload(
      groupId: groupId,
      content: content,
    );
    final r = await AuthenticatedHttpClient.post(
      buildCreateDocumentDraftUri(),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> createDocumentFromDefault({
    required String key,
    required String groupId,
    required Map<String, dynamic> content,
  }) async {
    final payload = buildDocumentDraftPayload(
      groupId: groupId,
      content: content,
    );
    final r = await AuthenticatedHttpClient.post(
      buildCreateDocumentFromDefaultUri(key: key, groupId: groupId),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Map<String, dynamic> buildDocumentDraftPayload({
    required String groupId,
    required Map<String, dynamic> content,
  }) {
    final variables = content['variables'];
    final clientName =
        variables is Map ? (variables['CLIENTE'] ?? '').toString().trim() : '';
    return <String, dynamic>{
      'groupId': groupId.trim(),
      if (clientName.isNotEmpty) 'clientName': clientName,
      ...content,
    };
  }

  Future<List<Map<String, dynamic>>> listDocumentsByGroup(
    String groupId, {
    String? search,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      buildListDocumentsByGroupUri(groupId, search: search),
      headers: _headers(),
    );
    final body = _tryDecodeBody(r.body);
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) {
      final raw = body is List
          ? body
          : body is Map && body['documents'] is List
              ? body['documents'] as List
              : body is Map && body['items'] is List
                  ? body['items'] as List
                  : null;
      if (raw != null) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
      throw Exception('Unexpected presupuesto document list payload');
    }
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message: _resolveErrorMessage(r, body),
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> issueDocument(String presupuestoId) async {
    final r = await AuthenticatedHttpClient.post(
      buildDocumentIssueUri(presupuestoId),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> createTemplate(
    Map<String, dynamic> payload,
  ) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/templates'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> updateTemplate(
    String templateId,
    Map<String, dynamic> payload,
  ) async {
    final r = await AuthenticatedHttpClient.patch(
      _u('/templates/${templateId.trim()}'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> deleteTemplate(String templateId) async {
    final r = await AuthenticatedHttpClient.delete(
      _u('/templates/${templateId.trim()}'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> uploadTemplateImage({
    required String templateId,
    required List<int> bytes,
    required String fileName,
    required String slot,
    String? label,
  }) async {
    final auth = await _requireAuthToken(
      path: '/templates/${templateId.trim()}/images',
      method: 'POST',
    );
    final req = http.MultipartRequest(
      'POST',
      _u('/templates/${templateId.trim()}/images'),
    );
    req.headers['Authorization'] = auth;
    req.fields['slot'] = slot;
    if ((label ?? '').trim().isNotEmpty) {
      req.fields['label'] = label!.trim();
    }
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> uploadPresupuestoTemplateContentImage({
    required String presupuestoId,
    required List<int> bytes,
    required String fileName,
    required String slot,
    String? label,
  }) async {
    final auth = await _requireAuthToken(
      path: '/${presupuestoId.trim()}/template-content/images',
      method: 'POST',
    );
    final req = http.MultipartRequest(
      'POST',
      _u('/${presupuestoId.trim()}/template-content/images'),
    );
    req.headers['Authorization'] = auth;
    req.fields['slot'] = slot;
    if ((label ?? '').trim().isNotEmpty) {
      req.fields['label'] = label!.trim();
    }
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> saveTemplateContent(
    String presupuestoId,
    Map<String, dynamic> payload,
  ) async {
    final r = await AuthenticatedHttpClient.patch(
      _u('/${presupuestoId.trim()}/template-content'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getTemplateContent(String presupuestoId) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/${presupuestoId.trim()}/template-content'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getTemplateVariables(
      String presupuestoId) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/${presupuestoId.trim()}/template-variables'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> updateTemplateVariables(
    String presupuestoId, {
    required Map<String, dynamic> variables,
    String? reason,
  }) async {
    final r = await AuthenticatedHttpClient.patch(
      _u('/${presupuestoId.trim()}/template-variables'),
      headers: _headers(),
      body: jsonEncode({
        'variables': variables,
        if ((reason ?? '').trim().isNotEmpty) 'reason': reason!.trim(),
      }),
    );
    return _decodeMap(r);
  }

  Future<http.Response> previewTemplatePdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/${id.trim()}/template-pdf/preview'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to preview editable presupuesto PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> previewSavedTemplatePdf(String templateId) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/templates/${templateId.trim()}/pdf/preview'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to preview saved presupuesto template PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> previewDefaultTemplatePdf({
    required String key,
    required String groupId,
  }) async {
    final encodedKey = Uri.encodeComponent(key.trim());
    final uri = Uri.parse('$_base/templates/defaults/$encodedKey/pdf/preview')
        .replace(queryParameters: {'groupId': groupId.trim()});
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to preview default presupuesto template PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> previewLiveTemplatePdf({
    required String groupId,
    required Map<String, dynamic> template,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/templates/pdf/preview'),
      headers: _headers(),
      body: jsonEncode({
        'groupId': groupId.trim(),
        'template': template,
      }),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to preview live presupuesto template PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> downloadTemplatePdf(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/${id.trim()}/template-pdf'),
      headers: _headers(),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to download editable presupuesto PDF (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<http.Response> downloadAllPdfsZip({
    required String groupId,
  }) async {
    final uri = Uri.parse('$_base/pdf/all').replace(
      queryParameters: {'groupId': groupId},
    );
    final headers = _headers();
    headers['Accept'] = 'application/zip';
    final r = await AuthenticatedHttpClient.get(uri, headers: headers);
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final body = _tryDecodeBody(r.body);
    throw PresupuestosApiException(
      statusCode: r.statusCode,
      message:
          'Failed to download presupuestos ZIP (${r.statusCode}): ${_resolveErrorMessage(r, body)}',
      code: _resolveErrorCode(body),
      details: _resolveErrorDetails(body),
    );
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final r =
        await AuthenticatedHttpClient.get(_u('/$id'), headers: _headers());
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> listSnapshots(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/${id.trim()}/snapshots'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getSnapshot({
    required String id,
    required String snapshotId,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/${id.trim()}/snapshots/${snapshotId.trim()}'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> getImportJsonPromptTemplate(String id) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/$id/import-json/prompt-template'),
      headers: _headers(),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> importJson(String id, dynamic payload) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/$id/import-json'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decodeMap(r);
  }

  Future<Map<String, dynamic>> extractImageOpenAi({
    required String id,
    required List<int> bytes,
    required String fileName,
    String fieldName = 'image',
  }) async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = headers['Authorization'] ?? '';
    if (auth.trim().isEmpty) {
      throw PresupuestosApiException(
          statusCode: 401, message: 'Not authenticated');
    }

    final req = http.MultipartRequest('POST', _u('/$id/extract-image'));
    req.headers['Authorization'] = auth;
    req.fields['method'] = 'openai';
    req.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );

    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }

  Future<String> _requireAuthToken({
    required String path,
    required String method,
  }) async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = headers['Authorization'] ?? '';
    if (auth.trim().isEmpty) {
      throw PresupuestosApiException(
          statusCode: 401, message: 'Not authenticated');
    }
    return auth;
  }

  Future<Map<String, dynamic>> _postMultipartImage({
    required String path,
    required List<int> bytes,
    required String fileName,
    String fieldName = 'image',
  }) async {
    final auth = await _requireAuthToken(path: path, method: 'POST');
    final req = http.MultipartRequest('POST', _u(path));
    req.headers['Authorization'] = auth;
    req.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> extractLinesOcr({
    required String id,
    required List<int> bytes,
    required String fileName,
    String fieldName = 'image',
    bool preview = false,
  }) async {
    final path = preview ? '/$id/lines/ocr-preview' : '/$id/lines/ocr';
    return _postMultipartImage(
      path: path,
      bytes: bytes,
      fileName: fileName,
      fieldName: fieldName,
    );
  }

  Future<Map<String, dynamic>> importLinesMultipart({
    required String id,
    required Map<String, dynamic> payload,
    String fieldName = 'file',
    String fileName = 'lines.json',
  }) async {
    final path = '/$id/lines/import';
    final auth = await _requireAuthToken(path: path, method: 'POST');
    final req = http.MultipartRequest('POST', _u(path));
    req.headers['Authorization'] = auth;
    req.files.add(
      http.MultipartFile.fromString(
        fieldName,
        jsonEncode(payload),
        filename: fileName,
      ),
    );
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeMap(response);
  }
}
