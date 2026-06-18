import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';

class AdvanceInvoiceConfigInput {
  final double percent;
  final String? description;

  const AdvanceInvoiceConfigInput({
    required this.percent,
    this.description,
  });
}

class PresupuestoFlowValidationResult {
  final bool isValid;
  final String? message;

  const PresupuestoFlowValidationResult._(this.isValid, this.message);

  const PresupuestoFlowValidationResult.valid() : this._(true, null);

  const PresupuestoFlowValidationResult.invalid(String message)
      : this._(false, message);
}

class PresupuestoInvoiceActionState {
  final bool canCreateAdvance;
  final bool canCreateFinal;
  final bool hasAdvance;
  final bool hasFinal;
  final String status;

  const PresupuestoInvoiceActionState({
    required this.canCreateAdvance,
    required this.canCreateFinal,
    required this.hasAdvance,
    required this.hasFinal,
    required this.status,
  });
}

class AdvanceInvoiceCandidate {
  final String id;
  final String number;
  final String status;
  final String? invoiceType;

  const AdvanceInvoiceCandidate({
    required this.id,
    required this.number,
    required this.status,
    this.invoiceType,
  });

  bool get isIssued => status.toLowerCase().contains('issued');
}

class PresupuestoLinkedInvoiceRecord {
  final String id;
  final String number;
  final String status;
  final String invoiceType;

  const PresupuestoLinkedInvoiceRecord({
    required this.id,
    required this.number,
    required this.status,
    required this.invoiceType,
  });

  bool get isAdvance => invoiceType == 'advance';
  bool get isFinal => invoiceType == 'final';
  bool get isStandard =>
      invoiceType == 'standard' || invoiceType == 'invoice';

  String get displayNumber => number.trim().isEmpty ? id : number;

  String get typeLabel {
    switch (invoiceType) {
      case 'advance':
        return 'Advance';
      case 'final':
        return 'Final';
      case 'standard':
      case 'invoice':
        return 'Standard';
      default:
        return invoiceType.trim().isEmpty ? 'Invoice' : invoiceType;
    }
  }
}

bool isPresupuestoIssuedOrAccepted(Map<String, dynamic> presupuesto) {
  final status = (presupuesto['status'] ?? '').toString().trim().toLowerCase();
  if (status.isEmpty) return false;
  return status.contains('issued') ||
      status.contains('accept') ||
      status.contains('approved');
}

PresupuestoFlowValidationResult validateAdvanceConfig(
  AdvanceInvoiceConfigInput input,
) {
  if (input.percent <= 0 || input.percent > 100) {
    return const PresupuestoFlowValidationResult.invalid(
      'Percent must be greater than 0 and less than or equal to 100.',
    );
  }
  return const PresupuestoFlowValidationResult.valid();
}

Map<String, dynamic> buildAdvanceInvoicePayload(
  AdvanceInvoiceConfigInput input, {
  String? notes,
}) {
  final validation = validateAdvanceConfig(input);
  if (!validation.isValid) {
    throw ArgumentError(validation.message);
  }
  final trimmedDescription = input.description?.trim();
  final trimmedNotes = notes?.trim();
  return <String, dynamic>{
    'advanceConfig': <String, dynamic>{
      'percent': input.percent,
      if (trimmedDescription != null && trimmedDescription.isNotEmpty)
        'description': trimmedDescription,
    },
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) 'notes': trimmedNotes,
  };
}

CreateAdvanceInvoiceFromPresupuestoRequest buildAdvanceInvoiceRequest(
  AdvanceInvoiceConfigInput input, {
  String? notes,
}) {
  final payload = buildAdvanceInvoicePayload(input, notes: notes);
  final config = Map<String, dynamic>.from(
    payload['advanceConfig'] as Map<String, dynamic>,
  );
  return CreateAdvanceInvoiceFromPresupuestoRequest(
    advanceConfig: CreateAdvanceInvoiceConfig(
      percent: (config['percent'] as num).toDouble(),
      description: config['description']?.toString(),
    ),
    notes: payload['notes']?.toString(),
  );
}

Map<String, dynamic> buildFinalInvoicePayload({
  String? advanceInvoiceId,
  String? notes,
}) {
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

CreateFinalInvoiceFromPresupuestoRequest buildFinalInvoiceRequest({
  String? advanceInvoiceId,
  String? notes,
}) {
  return CreateFinalInvoiceFromPresupuestoRequest(
    advanceInvoiceId: advanceInvoiceId,
    notes: notes,
  );
}

PresupuestoInvoiceActionState resolvePresupuestoInvoiceActionState(
  Map<String, dynamic> presupuesto,
) {
  final status = (presupuesto['status'] ?? '').toString().trim().toLowerCase();
  final eligible = isPresupuestoIssuedOrAccepted(presupuesto);
  final linked = extractLinkedInvoiceRecordsFromPresupuesto(presupuesto);
  final related = extractAdvanceInvoiceCandidatesFromPresupuesto(presupuesto);
  final hasAdvance = related.isNotEmpty ||
      linked.any((record) => record.isAdvance) ||
      (presupuesto['advanceInvoiceId'] ?? '').toString().trim().isNotEmpty ||
      (presupuesto['convertedAdvanceInvoiceId'] ?? '')
          .toString()
          .trim()
          .isNotEmpty;
  final hasFinal = linked.any((record) => record.isFinal) ||
      _hasLinkedInvoiceType(presupuesto, 'final') ||
      (presupuesto['finalInvoiceId'] ?? '').toString().trim().isNotEmpty ||
      (presupuesto['convertedFinalInvoiceId'] ?? '')
          .toString()
          .trim()
          .isNotEmpty;

  return PresupuestoInvoiceActionState(
    canCreateAdvance: eligible && !hasAdvance,
    canCreateFinal: eligible && !hasFinal,
    hasAdvance: hasAdvance,
    hasFinal: hasFinal,
    status: status,
  );
}

List<PresupuestoLinkedInvoiceRecord> extractLinkedInvoiceRecordsFromPresupuesto(
  Map<String, dynamic> presupuesto,
) {
  final items = <PresupuestoLinkedInvoiceRecord>[];
  final seen = <String>{};
  final presupuestoId = _presupuestoObjectId(presupuesto);

  void addRecord({
    required String id,
    required String number,
    required String status,
    required String invoiceType,
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty || seen.contains(normalizedId)) return;
    items.add(
      PresupuestoLinkedInvoiceRecord(
        id: normalizedId,
        number: number.trim().isEmpty ? normalizedId : number.trim(),
        status: status.trim(),
        invoiceType: invoiceType.trim().isEmpty ? 'invoice' : invoiceType.trim(),
      ),
    );
    seen.add(normalizedId);
  }

  final buckets = <MapEntry<String, dynamic>>[
    MapEntry<String, dynamic>('advanceInvoices', presupuesto['advanceInvoices']),
    MapEntry<String, dynamic>('finalInvoices', presupuesto['finalInvoices']),
    MapEntry<String, dynamic>('standardInvoices', presupuesto['standardInvoices']),
    MapEntry<String, dynamic>('relatedInvoices', presupuesto['relatedInvoices']),
    MapEntry<String, dynamic>('linkedInvoices', presupuesto['linkedInvoices']),
    MapEntry<String, dynamic>('invoices', presupuesto['invoices']),
  ];

  for (final entry in buckets) {
    final bucketName = entry.key;
    final bucket = entry.value;
    if (bucket is! List) continue;
    for (final raw in bucket.whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      if (!_matchesPresupuestoLink(map, presupuestoId)) continue;
      final id = (map['_id'] ?? map['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      String type = (map['invoiceType'] ?? map['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (type.isEmpty) {
        if (bucketName == 'advanceInvoices') {
          type = 'advance';
        } else if (bucketName == 'finalInvoices') {
          type = 'final';
        } else {
          type = 'standard';
        }
      }
      addRecord(
        id: id,
        number: (map['invoiceNumber'] ?? map['number'] ?? id).toString(),
        status: (map['status'] ?? '').toString(),
        invoiceType: type,
      );
    }
  }

  _addRecordsFromConvertedInvoiceIds(
    presupuesto,
    addRecord: addRecord,
  );

  final convertedAdvance = _asMap(presupuesto['convertedAdvanceInvoice']);
  if (convertedAdvance != null) {
    addRecord(
      id: _recordId(convertedAdvance),
      number: _recordNumber(convertedAdvance),
      status: _recordStatus(convertedAdvance),
      invoiceType: 'advance',
    );
  }
  final convertedFinal = _asMap(presupuesto['convertedFinalInvoice']);
  if (convertedFinal != null) {
    addRecord(
      id: _recordId(convertedFinal),
      number: _recordNumber(convertedFinal),
      status: _recordStatus(convertedFinal),
      invoiceType: 'final',
    );
  }
  final convertedInvoice = _asMap(presupuesto['convertedInvoice']);
  if (convertedInvoice != null) {
    addRecord(
      id: _recordId(convertedInvoice),
      number: _recordNumber(convertedInvoice),
      status: _recordStatus(convertedInvoice),
      invoiceType: _recordInvoiceType(convertedInvoice, fallback: 'standard'),
    );
  }

  addRecord(
    id: (presupuesto['advanceInvoiceId'] ?? '').toString(),
    number: (presupuesto['advanceInvoiceNumber'] ??
            presupuesto['advanceInvoiceId'] ??
            '')
        .toString(),
    status: (presupuesto['advanceInvoiceStatus'] ?? '').toString(),
    invoiceType: 'advance',
  );
  addRecord(
    id: (presupuesto['convertedAdvanceInvoiceId'] ?? '').toString(),
    number: (presupuesto['convertedAdvanceInvoiceNumber'] ??
            presupuesto['advanceInvoiceNumber'] ??
            presupuesto['convertedAdvanceInvoiceId'] ??
            '')
        .toString(),
    status: (presupuesto['convertedAdvanceInvoiceStatus'] ??
            presupuesto['advanceInvoiceStatus'] ??
            '')
        .toString(),
    invoiceType: 'advance',
  );
  addRecord(
    id: (presupuesto['finalInvoiceId'] ?? '').toString(),
    number:
        (presupuesto['finalInvoiceNumber'] ?? presupuesto['finalInvoiceId'] ?? '')
            .toString(),
    status: (presupuesto['finalInvoiceStatus'] ?? '').toString(),
    invoiceType: 'final',
  );
  addRecord(
    id: (presupuesto['convertedFinalInvoiceId'] ?? '').toString(),
    number: (presupuesto['convertedFinalInvoiceNumber'] ??
            presupuesto['finalInvoiceNumber'] ??
            presupuesto['convertedFinalInvoiceId'] ??
            '')
        .toString(),
    status: (presupuesto['convertedFinalInvoiceStatus'] ??
            presupuesto['finalInvoiceStatus'] ??
            '')
        .toString(),
    invoiceType: 'final',
  );
  addRecord(
    id: (presupuesto['convertedInvoiceId'] ??
            presupuesto['invoiceId'] ??
            presupuesto['convertedToInvoiceId'] ??
            '')
        .toString(),
    number: (presupuesto['convertedInvoiceNumber'] ??
            presupuesto['invoiceNumber'] ??
            presupuesto['convertedInvoiceId'] ??
            presupuesto['invoiceId'] ??
            '')
        .toString(),
    status: (presupuesto['convertedInvoiceStatus'] ?? '').toString(),
    invoiceType: 'standard',
  );

  items.sort((a, b) {
    const order = <String, int>{
      'advance': 0,
      'final': 1,
      'standard': 2,
      'invoice': 2,
    };
    final aRank = order[a.invoiceType] ?? 9;
    final bRank = order[b.invoiceType] ?? 9;
    if (aRank != bRank) return aRank.compareTo(bRank);
    final numberCompare =
        compareInvoiceLikeNumberDesc(a.displayNumber, b.displayNumber);
    if (numberCompare != 0) return numberCompare;
    return a.displayNumber.toLowerCase().compareTo(b.displayNumber.toLowerCase());
  });
  return items;
}

List<AdvanceInvoiceCandidate> extractAdvanceInvoiceCandidatesFromPresupuesto(
  Map<String, dynamic> presupuesto,
) {
  final presupuestoId = _presupuestoObjectId(presupuesto);
  final buckets = <MapEntry<String, dynamic>>[
    MapEntry<String, dynamic>('advanceInvoices', presupuesto['advanceInvoices']),
    MapEntry<String, dynamic>('relatedInvoices', presupuesto['relatedInvoices']),
    MapEntry<String, dynamic>('linkedInvoices', presupuesto['linkedInvoices']),
    MapEntry<String, dynamic>('invoices', presupuesto['invoices']),
  ];
  final items = <AdvanceInvoiceCandidate>[];
  final seen = <String>{};

  for (final entry in buckets) {
    final bucketName = entry.key;
    final bucket = entry.value;
    if (bucket is! List) continue;
    for (final raw in bucket.whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      if (!_matchesPresupuestoLink(map, presupuestoId)) continue;
      final id = (map['_id'] ?? map['id'] ?? '').toString().trim();
      if (id.isEmpty || seen.contains(id)) continue;
      final type = (map['invoiceType'] ?? map['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (bucketName != 'advanceInvoices' && type != 'advance') continue;
      final number = (map['invoiceNumber'] ?? map['number'] ?? id)
          .toString()
          .trim();
      final status = (map['status'] ?? '').toString().trim();
      items.add(AdvanceInvoiceCandidate(
        id: id,
        number: number.isEmpty ? id : number,
        status: status,
        invoiceType: type.isEmpty ? null : type,
      ));
      seen.add(id);
    }
  }

  final convertedInvoiceIds = presupuesto['convertedInvoiceIds'];
  if (convertedInvoiceIds is List) {
    for (final raw in convertedInvoiceIds) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (!_matchesPresupuestoLink(map, presupuestoId)) continue;
      final id = _recordId(map);
      if (id.isEmpty || seen.contains(id)) continue;
      final type = _recordInvoiceType(map);
      if (type != 'advance') continue;
      items.add(
        AdvanceInvoiceCandidate(
          id: id,
          number: _recordNumber(map).isEmpty ? id : _recordNumber(map),
          status: _recordStatus(map),
          invoiceType: type,
        ),
      );
      seen.add(id);
    }
  }

  final convertedAdvance = _asMap(presupuesto['convertedAdvanceInvoice']);
  if (convertedAdvance != null) {
    final id = _recordId(convertedAdvance);
    if (id.isNotEmpty && !seen.contains(id)) {
      items.add(
        AdvanceInvoiceCandidate(
          id: id,
          number: _recordNumber(convertedAdvance).isEmpty
              ? id
              : _recordNumber(convertedAdvance),
          status: _recordStatus(convertedAdvance),
          invoiceType: 'advance',
        ),
      );
      seen.add(id);
    }
  }

  final singleAdvanceId =
      (presupuesto['advanceInvoiceId'] ?? '').toString().trim();
  if (singleAdvanceId.isNotEmpty && !seen.contains(singleAdvanceId)) {
    items.add(AdvanceInvoiceCandidate(
      id: singleAdvanceId,
      number: singleAdvanceId,
      status: '',
      invoiceType: 'advance',
    ));
  }

  final convertedAdvanceId =
      (presupuesto['convertedAdvanceInvoiceId'] ?? '').toString().trim();
  if (convertedAdvanceId.isNotEmpty && !seen.contains(convertedAdvanceId)) {
    items.add(
      AdvanceInvoiceCandidate(
        id: convertedAdvanceId,
        number: (presupuesto['convertedAdvanceInvoiceNumber'] ??
                presupuesto['advanceInvoiceNumber'] ??
                convertedAdvanceId)
            .toString()
            .trim(),
        status: (presupuesto['convertedAdvanceInvoiceStatus'] ??
                presupuesto['advanceInvoiceStatus'] ??
                '')
            .toString()
            .trim(),
        invoiceType: 'advance',
      ),
    );
  }

  items.sort((a, b) {
    if (a.isIssued != b.isIssued) return a.isIssued ? -1 : 1;
    final numberCompare = compareInvoiceLikeNumberDesc(a.number, b.number);
    if (numberCompare != 0) return numberCompare;
    return a.number.toLowerCase().compareTo(b.number.toLowerCase());
  });
  return items;
}

int compareInvoiceLikeNumberAsc(String a, String b) {
  final aNumber = a.trim();
  final bNumber = b.trim();
  final aDigits = RegExp(r'\d+')
      .allMatches(aNumber)
      .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
      .toList(growable: false);
  final bDigits = RegExp(r'\d+')
      .allMatches(bNumber)
      .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
      .toList(growable: false);

  final common = aDigits.length < bDigits.length ? aDigits.length : bDigits.length;
  for (var i = 0; i < common; i++) {
    final compare = aDigits[i].compareTo(bDigits[i]);
    if (compare != 0) return compare;
  }
  if (aDigits.length != bDigits.length) {
    return aDigits.length.compareTo(bDigits.length);
  }
  return aNumber.toLowerCase().compareTo(bNumber.toLowerCase());
}

int compareInvoiceLikeNumberDesc(String a, String b) {
  return compareInvoiceLikeNumberAsc(b, a);
}

String _presupuestoObjectId(Map<String, dynamic> presupuesto) {
  return (presupuesto['_id'] ?? presupuesto['id'] ?? '').toString().trim();
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _recordId(Map<String, dynamic> record) {
  return (record['_id'] ?? record['id'] ?? '').toString().trim();
}

String _recordNumber(Map<String, dynamic> record) {
  return (record['invoiceNumber'] ?? record['number'] ?? '').toString().trim();
}

String _recordStatus(Map<String, dynamic> record) {
  return (record['status'] ?? '').toString().trim();
}

String _recordInvoiceType(
  Map<String, dynamic> record, {
  String fallback = '',
}) {
  final type = (record['invoiceType'] ?? record['type'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  return type.isEmpty ? fallback : type;
}

bool _matchesPresupuestoLink(
  Map<String, dynamic> record,
  String presupuestoId,
) {
  if (presupuestoId.isEmpty) return true;
  final linkedId = (record['sourcePresupuestoId'] ??
          record['presupuestoId'] ??
          record['budgetId'] ??
          record['sourceBudgetId'] ??
          '')
      .toString()
      .trim();
  return linkedId.isEmpty || linkedId == presupuestoId;
}

void _addRecordsFromConvertedInvoiceIds(
  Map<String, dynamic> presupuesto, {
  required void Function({
    required String id,
    required String number,
    required String status,
    required String invoiceType,
  })
      addRecord,
}) {
  final convertedInvoiceIds = presupuesto['convertedInvoiceIds'];
  if (convertedInvoiceIds is! List) return;
  for (final raw in convertedInvoiceIds) {
    if (raw is String) {
      addRecord(
        id: raw,
        number: raw,
        status: '',
        invoiceType: 'standard',
      );
      continue;
    }
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final id = _recordId(map);
    if (id.isEmpty) continue;
    addRecord(
      id: id,
      number: _recordNumber(map).isEmpty ? id : _recordNumber(map),
      status: _recordStatus(map),
      invoiceType: _recordInvoiceType(map, fallback: 'standard'),
    );
  }
}

bool _hasLinkedInvoiceType(Map<String, dynamic> presupuesto, String expectedType) {
  final normalized = expectedType.trim().toLowerCase();
  final buckets = <dynamic>[
    presupuesto['relatedInvoices'],
    presupuesto['linkedInvoices'],
    presupuesto['invoices'],
    presupuesto['convertedInvoiceIds'],
  ];
  for (final bucket in buckets) {
    if (bucket is! List) continue;
    for (final raw in bucket.whereType<Map>()) {
      if (!_matchesPresupuestoLink(raw.cast<String, dynamic>(),
          _presupuestoObjectId(presupuesto))) {
        continue;
      }
      final type = (raw['invoiceType'] ?? raw['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (type == normalized) return true;
    }
  }
  return false;
}
