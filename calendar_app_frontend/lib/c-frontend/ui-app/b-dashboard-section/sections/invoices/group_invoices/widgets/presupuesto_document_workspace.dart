import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';

enum PresupuestoDocumentSection { drafts, issued }

class PresupuestoDocumentWorkspace {
  PresupuestoDocumentWorkspace({required this.api});

  final PresupuestosApi api;
  final Set<String> _issuingIds = <String>{};
  List<Map<String, dynamic>> _documents = const [];

  List<Map<String, dynamic>> get documents => List.unmodifiable(_documents);

  List<Map<String, dynamic>> get drafts => filterPresupuestoDocuments(
        _documents,
        section: PresupuestoDocumentSection.drafts,
      );

  List<Map<String, dynamic>> get issued => filterPresupuestoDocuments(
        _documents,
        section: PresupuestoDocumentSection.issued,
      );

  bool isIssuing(String id) => _issuingIds.contains(id.trim());

  Future<List<Map<String, dynamic>>> refresh(String groupId) async {
    _documents = (await api.listDocumentsByGroup(groupId))
        .where(presupuestoHasDocumentContent)
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
    return documents;
  }

  Future<Map<String, dynamic>> issue(
    Map<String, dynamic> document,
  ) async {
    final validation = presupuestoDocumentIssueValidation(document);
    if (validation != null) {
      throw PresupuestoDocumentValidationException(validation);
    }
    final id = presupuestoDocumentId(document);
    if (!_issuingIds.add(id)) {
      throw const PresupuestoDocumentIssueInProgressException();
    }
    try {
      final response = await api.issueDocument(id);
      final responseDocument = presupuestoDocumentFromResponse(response);
      final updated = <String, dynamic>{
        ...document,
        ...?responseDocument,
      };
      _replace(updated);
      return updated;
    } finally {
      _issuingIds.remove(id);
    }
  }

  Future<void> remove(Map<String, dynamic> document) async {
    final id = presupuestoDocumentId(document);
    await api.remove(id);
    _documents = _documents
        .where((item) => presupuestoDocumentId(item) != id)
        .toList(growable: false);
  }

  void _replace(Map<String, dynamic> updated) {
    final id = presupuestoDocumentId(updated);
    _documents = [
      for (final item in _documents)
        if (presupuestoDocumentId(item) == id)
          Map<String, dynamic>.from(updated)
        else
          item,
    ];
  }
}

class PresupuestoDocumentValidationException implements Exception {
  const PresupuestoDocumentValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PresupuestoDocumentIssueInProgressException implements Exception {
  const PresupuestoDocumentIssueInProgressException();

  @override
  String toString() => 'Este presupuesto ya se esta emitiendo.';
}

List<Map<String, dynamic>> filterPresupuestoDocuments(
  Iterable<Map<String, dynamic>> documents, {
  required PresupuestoDocumentSection section,
}) {
  final expected =
      section == PresupuestoDocumentSection.drafts ? 'draft' : 'issued';
  return documents
      .where(presupuestoHasDocumentContent)
      .where((item) => presupuestoDocumentStatus(item) == expected)
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}

bool presupuestoHasDocumentContent(Map<String, dynamic> document) =>
    document['hasDocumentContent'] == true;

String presupuestoDocumentStatus(Map<String, dynamic> document) =>
    (document['status'] ?? '').toString().trim().toLowerCase();

String presupuestoDocumentId(Map<String, dynamic> document) =>
    (document['presupuestoId'] ?? document['_id'] ?? document['id'] ?? '')
        .toString()
        .trim();

String presupuestoDocumentClientName(Map<String, dynamic> document) {
  for (final value in <Object?>[
    document['clientName'],
    document['customerName'],
    _nested(document, 'clientSnapshot')?['name'],
    _nested(document, 'variables')?['CLIENTE'],
    _nested(document, 'documentContent')?['variables'] is Map
        ? (_nested(document, 'documentContent')!['variables'] as Map)['CLIENTE']
        : null,
    _nested(document, 'templateContent')?['variables'] is Map
        ? (_nested(document, 'templateContent')!['variables'] as Map)['CLIENTE']
        : null,
    _nested(document, 'content')?['variables'] is Map
        ? (_nested(document, 'content')!['variables'] as Map)['CLIENTE']
        : null,
  ]) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

String presupuestoDocumentTitle(Map<String, dynamic> document) {
  for (final value in <Object?>[
    document['documentTitle'],
    document['title'],
    _nested(document, 'documentContent')?['title'],
    _nested(document, 'templateContent')?['title'],
    _nested(document, 'content')?['title'],
    document['name'],
  ]) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return 'Documento sin titulo';
}

int presupuestoDocumentImageCount(Map<String, dynamic> document) {
  final count = document['imageCount'];
  if (count is num) return count.toInt();
  for (final source in <Map<String, dynamic>?>[
    _nested(document, 'documentContent'),
    _nested(document, 'templateContent'),
    _nested(document, 'content'),
  ]) {
    final images = source?['images'];
    if (images is List) return images.length;
  }
  return 0;
}

num? presupuestoDocumentAmount(Map<String, dynamic> document) {
  final values = <Object?>[
    document['amount'],
    document['total'],
    _nested(document, 'totals')?['total'],
    _nested(document, 'totals')?['grandTotal'],
  ];
  for (final variables in <Map<String, dynamic>?>[
    _nested(document, 'variables'),
    _nested(_nested(document, 'documentContent') ?? const {}, 'variables'),
    _nested(_nested(document, 'templateContent') ?? const {}, 'variables'),
    _nested(_nested(document, 'content') ?? const {}, 'variables'),
  ]) {
    if (variables == null) continue;
    values.addAll(<Object?>[
      variables['IMPORTE_MENSUAL'],
      variables['IMPORTE'],
      variables['PRECIO_TOTAL'],
      variables['TOTAL'],
    ]);
  }

  num? zeroFallback;
  for (final value in values) {
    final parsed = _localizedNumber(value);
    if (parsed == null) continue;
    if (parsed != 0) return parsed;
    zeroFallback ??= parsed;
  }
  return zeroFallback;
}

num? _localizedNumber(Object? value) {
  if (value is num) return value;
  var text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  text = text.replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (text.contains(',') && text.contains('.')) {
    if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '');
    }
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  }
  return num.tryParse(text);
}

String? presupuestoDocumentIssueValidation(
  Map<String, dynamic> document,
) {
  if (presupuestoDocumentStatus(document) != 'draft') {
    return 'Este presupuesto ya no esta en borrador. Actualiza la lista.';
  }
  if (presupuestoDocumentClientName(document).isEmpty) {
    return 'Indica el nombre del cliente antes de emitir.';
  }
  if (!presupuestoHasDocumentContent(document)) {
    return 'El presupuesto no contiene un documento para emitir.';
  }
  if (presupuestoDocumentId(document).isEmpty) {
    return 'No se pudo identificar el presupuesto.';
  }
  return null;
}

Map<String, dynamic>? presupuestoDocumentFromResponse(
  Map<String, dynamic> response,
) {
  for (final source in <Object?>[
    response['presupuesto'],
    response['document'],
    response['data'],
    response,
  ]) {
    if (source is Map) return Map<String, dynamic>.from(source);
  }
  return null;
}

bool isAlreadyIssuedDocumentError(PresupuestosApiException error) {
  final code = (error.code ?? '').toLowerCase();
  final message = error.message.toLowerCase();
  return code.contains('already_issued') ||
      code.contains('presupuesto_issued') ||
      message.contains('already issued') ||
      message.contains('ya emitido') ||
      message.contains('ya esta emitido');
}

String presupuestoDocumentIssueErrorMessage(
  PresupuestosApiException error,
) {
  final source = '${error.code ?? ''} ${error.message}'.toLowerCase();
  final billingIncomplete = source.contains('billing') ||
      source.contains('issuer') ||
      source.contains('fiscal') ||
      source.contains('facturaci');
  return billingIncomplete
      ? '${error.message} Completa el perfil de facturacion antes de emitir.'
      : error.message;
}

Map<String, dynamic>? _nested(
  Map<String, dynamic> source,
  String key,
) {
  final value = source[key];
  return value is Map ? Map<String, dynamic>.from(value) : null;
}
