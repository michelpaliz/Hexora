import 'package:hexora/models/presupuesto/presupuesto_kind.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';

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
    final listed = (await api.listDocumentsByGroup(groupId))
        .where(presupuestoHasDocumentContent)
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
    _documents = await Future.wait(listed.map(_hydrateZeroAmountSummary));
    return documents;
  }

  Future<Map<String, dynamic>> _hydrateZeroAmountSummary(
    Map<String, dynamic> document,
  ) async {
    final amount = document.containsKey('amount')
        ? _localizedNumber(document['amount'])
        : null;
    if (amount != 0 || _cleaningScheduleAmount(document) != null) {
      return document;
    }
    final id = presupuestoDocumentId(document);
    if (id.isEmpty) return document;
    try {
      final response = await api.getTemplateContent(id);
      final content = _nested(response, 'content');
      if (content == null) return document;
      return <String, dynamic>{
        ...document,
        'documentContent': content,
      };
    } catch (_) {
      return document;
    }
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

bool presupuestoHasDocumentContent(Map<String, dynamic> document) {
  return PresupuestoKind.fromJson(document) == PresupuestoKind.document;
}

bool presupuestoHasProposalContent(Map<String, dynamic> document) {
  if (document['proposalTemplate'] is Map ||
      document['documentContent'] is Map ||
      document['templateContent'] is Map) {
    return true;
  }
  final contentFlag = document['hasDocumentContent'];
  return contentFlag == true ||
      contentFlag?.toString().trim().toLowerCase() == 'true';
}

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
  final cleaningDocument = _isCleaningDocument(document);
  for (final value in <Object?>[
    document['documentTitle'],
    document['title'],
    _nested(document, 'documentContent')?['title'],
    _nested(document, 'templateContent')?['title'],
    _nested(document, 'content')?['title'],
    document['name'],
  ]) {
    final text = value?.toString().trim() ?? '';
    if (cleaningDocument && _isGardenPoolTitle(text)) continue;
    if (text.isNotEmpty) return text;
  }
  return cleaningDocument
      ? 'Limpieza anual de escaleras y zonas comunes'
      : 'Documento sin titulo';
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
  // The list endpoint now returns an authoritative `amount` (see
  // `amountSource`: 'templateVariable' or 'totals') computed server-side, so
  // trust it directly whenever present instead of guessing across fields.
  if (document.containsKey('amount')) {
    final parsed = _localizedNumber(document['amount']);
    if (parsed != null && parsed != 0) return parsed;
  }

  final scheduleAmount = _cleaningScheduleAmount(document);
  if (scheduleAmount != null) return scheduleAmount;

  // Fallback for payloads that predate the authoritative `amount` field.
  final values = <Object?>[
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
      variables['TOTAL_MENSUAL'],
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

({num? taxableBase, num? vat, num? total}) presupuestoDocumentFinancials(
  Map<String, dynamic> document,
) {
  final total = presupuestoDocumentAmount(document);
  final sources = <Map<String, dynamic>>[
    document,
    ...<Map<String, dynamic>?>[
      _nested(document, 'documentContent'),
      _nested(document, 'templateContent'),
      _nested(document, 'content'),
    ].whereType<Map<String, dynamic>>(),
  ];

  num? firstValue(Iterable<Object?> values) {
    for (final value in values) {
      final parsed = _localizedNumber(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  final directBase = firstValue([
    for (final source in sources) ...[
      source['taxableBase'],
      source['baseAmount'],
      source['subtotal'],
      _nested(source, 'totals')?['taxableBase'],
      _nested(source, 'totals')?['base'],
      _nested(source, 'totals')?['subtotal'],
    ],
  ]);
  final directVat = firstValue([
    for (final source in sources) ...[
      source['taxTotal'],
      source['vatTotal'],
      source['ivaTotal'],
      _nested(source, 'totals')?['taxTotal'],
      _nested(source, 'totals')?['vatTotal'],
      _nested(source, 'totals')?['ivaTotal'],
      _nested(source, 'totals')?['iva'],
    ],
  ]);
  final hasEmptyFinancialPlaceholders = total != null &&
      total != 0 &&
      (directBase ?? 0) == 0 &&
      (directVat ?? 0) == 0;
  if (!hasEmptyFinancialPlaceholders &&
      (directBase != null || directVat != null)) {
    return (
      taxableBase: directBase ??
          (total != null && directVat != null ? total - directVat : null),
      vat: directVat ??
          (total != null && directBase != null ? total - directBase : null),
      total: total,
    );
  }

  for (final source in sources) {
    for (final key in const ['lines', 'blocks']) {
      final rows = source[key];
      if (rows is! List || rows.isEmpty) continue;
      num base = 0;
      num vat = 0;
      var found = false;
      for (final raw in rows.whereType<Map>()) {
        if (raw['isBillable'] == false) continue;
        final quantity = _localizedNumber(raw['quantity'] ?? raw['qty']) ?? 1;
        final unitPrice = _localizedNumber(
          raw['unitPrice'] ?? raw['price'] ?? raw['unit_price'],
        );
        final discount = (_localizedNumber(
                  raw['discountRate'] ?? raw['discountPercent'],
                ) ??
                0)
            .clamp(0, 100);
        final taxRate = _localizedNumber(
              raw['taxRate'] ?? raw['vatRate'] ?? raw['tax'] ?? raw['iva'],
            ) ??
            0;
        final explicitBase = _localizedNumber(
          raw['lineSubtotal'] ?? raw['taxableBase'] ?? raw['baseAmount'],
        );
        final explicitVat = _localizedNumber(
          raw['lineTax'] ?? raw['taxAmount'] ?? raw['vatAmount'],
        );
        final explicitTotal =
            _localizedNumber(raw['lineTotal'] ?? raw['total']);
        num? lineBase = explicitBase;
        if (lineBase == null && unitPrice != null) {
          lineBase = quantity * unitPrice * (1 - discount / 100);
        } else if (lineBase == null && explicitTotal != null) {
          lineBase = taxRate == 0
              ? explicitTotal
              : explicitTotal / (1 + taxRate / 100);
        }
        if (lineBase == null) continue;
        base += lineBase;
        vat += explicitVat ??
            (explicitTotal != null
                ? explicitTotal - lineBase
                : lineBase * taxRate / 100);
        found = true;
      }
      if (!found) continue;
      final discountAmount = _localizedNumber(
        source['discountAmount'] ??
            source['discount'] ??
            _nested(source, 'totals')?['discountAmount'],
      );
      final discountPercent = _localizedNumber(
        source['discountPercent'] ??
            source['discountRate'] ??
            _nested(source, 'totals')?['discountPercent'],
      );
      final effectiveDiscount = discountAmount != null
          ? discountAmount.clamp(0, base)
          : discountPercent != null
              ? (base * discountPercent.clamp(0, 100) / 100)
              : 0;
      if (effectiveDiscount > 0 && base > 0) {
        final ratio = (base - effectiveDiscount) / base;
        base -= effectiveDiscount;
        vat *= ratio;
      }
      final calculatedTotal = base + vat;
      if (total != null && (calculatedTotal - total).abs() > 0.01) {
        return (taxableBase: null, vat: null, total: total);
      }
      return (taxableBase: base, vat: vat, total: total ?? calculatedTotal);
    }
  }
  return (taxableBase: null, vat: null, total: total);
}

List<String> presupuestoDocumentConcepts(Map<String, dynamic> document) {
  final title = presupuestoDocumentTitle(document).trim().toLowerCase();
  final client = presupuestoDocumentClientName(document).trim().toLowerCase();
  final concepts = <String>[];
  final ignored = <String>{
    '',
    title,
    client,
    'presupuesto',
    'propuesta',
    'condiciones',
    'condiciones de pago',
    'anexo',
    'imagenes',
    'imágenes',
  };

  void add(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    final normalized = value.toLowerCase();
    if (value.length < 3 || ignored.contains(normalized)) return;
    if (!concepts.any((item) => item.toLowerCase() == normalized)) {
      concepts.add(value);
    }
  }

  void addRow(Map row) {
    for (final key in const [
      'conceptTitle',
      'serviceDescription',
      'description',
      'concept',
      'name',
      'text',
    ]) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        add(value);
        break;
      }
    }
  }

  final sources = <Map<String, dynamic>>[
    document,
    ...<Map<String, dynamic>?>[
      _nested(document, 'documentContent'),
      _nested(document, 'templateContent'),
      _nested(document, 'content'),
    ].whereType<Map<String, dynamic>>(),
  ];
  for (final source in sources) {
    for (final key in const [
      'concept',
      'serviceDescription',
      'serviceName',
      'serviceType',
      'description',
    ]) {
      add(source[key]);
    }
    final variables = source['variables'];
    if (variables is Map) {
      for (final key in const [
        'CONCEPTO',
        'SERVICIO',
        'SERVICIO_MANTENIMIENTO',
        'DESCRIPCION_SERVICIO',
        'TIPO_SERVICIO',
      ]) {
        add(variables[key]);
      }
    }
    for (final key in const ['lines', 'blocks', 'items']) {
      final rows = source[key];
      if (rows is List) {
        for (final raw in rows) {
          if (raw is Map) {
            addRow(raw);
          } else {
            add(raw);
          }
        }
      }
    }
    final sections = source['sections'];
    if (sections is List) {
      for (final rawSection in sections.whereType<Map>()) {
        add(rawSection['serviceDescription']);
        add(rawSection['description']);
        add(rawSection['title']);
        final items = rawSection['items'];
        if (items is List) {
          for (final item in items) {
            item is Map ? addRow(item) : add(item);
          }
        }
      }
    }
  }
  if (concepts.isEmpty) {
    final fallback = _presupuestoServiceConcept(document);
    if (fallback != null) concepts.add(fallback);
  }
  return concepts;
}

String? _presupuestoServiceConcept(Map<String, dynamic> document) {
  final title = presupuestoDocumentTitle(document).toLowerCase();
  final templateKey = (document['templateKey'] ??
          _nested(document, 'documentContent')?['templateKey'] ??
          _nested(document, 'templateContent')?['templateKey'])
      ?.toString()
      .toLowerCase();
  final searchable = '$title ${templateKey ?? ''}'
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  final hasGarden = searchable.contains('jardin') ||
      searchable.contains('garden') ||
      searchable.contains('paisaj');
  final hasPool = searchable.contains('piscina') || searchable.contains('pool');
  if (hasGarden && hasPool) return 'Jardines y piscinas';
  if (hasGarden) return 'Jardines';
  if (hasPool) return 'Piscinas';
  if (searchable.contains('escalera') ||
      searchable.contains('zonas comunes') ||
      searchable.contains('stair_cleaning')) {
    return 'Limpieza de escaleras y zonas comunes';
  }
  return null;
}

num? _cleaningScheduleAmount(Map<String, dynamic> document) {
  for (final source in <Map<String, dynamic>>[
    document,
    ...<Map<String, dynamic>?>[
      _nested(document, 'documentContent'),
      _nested(document, 'templateContent'),
      _nested(document, 'content'),
    ].whereType<Map<String, dynamic>>(),
  ]) {
    final sections = source['sections'];
    if (sections is! List) continue;
    var sourceTotal = 0.0;
    var found = false;
    for (final rawSection in sections) {
      if (rawSection is! Map) continue;
      final table = rawSection['table'];
      if (table is! Map) continue;
      final columns = table['columns'];
      final rows = table['rows'];
      if (columns is! List || rows is! List) continue;
      final totalIndex = columns.indexWhere((column) {
        final heading = _normalizeColumn(column?.toString() ?? '');
        return heading == 'TOTAL MENSUAL' ||
            heading == 'IMPORTE MENSUAL' ||
            heading == 'TOTAL';
      });
      if (totalIndex < 0) continue;
      for (final rawRow in rows) {
        if (rawRow is! List || totalIndex >= rawRow.length) continue;
        final value = _localizedNumber(rawRow[totalIndex]);
        if (value == null) continue;
        sourceTotal += value;
        found = true;
      }
    }
    if (found) return sourceTotal;
  }
  return null;
}

bool _isCleaningDocument(Map<String, dynamic> document) {
  for (final source in <Map<String, dynamic>>[
    document,
    ...<Map<String, dynamic>?>[
      _nested(document, 'documentContent'),
      _nested(document, 'templateContent'),
      _nested(document, 'content'),
    ].whereType<Map<String, dynamic>>(),
  ]) {
    final key = (source['key'] ??
            source['templateKey'] ??
            source['presupuestoType'] ??
            '')
        .toString()
        .trim();
    final rawLayout = source['pageLayout'];
    final layout = rawLayout is Map
        ? (rawLayout['key'] ?? rawLayout['name'] ?? '').toString().trim()
        : (rawLayout ?? '').toString().trim();
    if (key == 'stair_cleaning_annual_maintenance' ||
        layout == 'cleaning_three_page') {
      return true;
    }
    if (_cleaningScheduleAmount(source) != null) return true;
  }
  return false;
}

bool _isGardenPoolTitle(String value) {
  final normalized = value.toLowerCase();
  return normalized.contains('jardin') || normalized.contains('piscina');
}

String _normalizeColumn(String value) => value
    .trim()
    .toUpperCase()
    .replaceAll('_', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll('Á', 'A')
    .replaceAll('É', 'E')
    .replaceAll('Í', 'I')
    .replaceAll('Ó', 'O')
    .replaceAll('Ú', 'U');

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
  } else if (text.contains('.')) {
    final parts = text.split('.');
    if (parts.length > 1 && parts.last.length == 3) {
      text = parts.join();
    }
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
  if (!presupuestoHasProposalContent(document)) {
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
