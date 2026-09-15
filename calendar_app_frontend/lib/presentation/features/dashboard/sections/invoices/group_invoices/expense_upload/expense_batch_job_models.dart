class ExpenseBatchJobSnapshot {
  final String jobId;
  final String? backgroundJobId;
  final Map<String, dynamic>? status;
  final Map<String, dynamic>? result;

  const ExpenseBatchJobSnapshot({
    required this.jobId,
    this.backgroundJobId,
    this.status,
    this.result,
  });
}

class ExpenseBatchPreviewItem {
  final String id;
  final String tempId;
  final String fileName;
  String status;
  Map<String, dynamic> prediction;
  final Map<String, dynamic> confidence;
  final List<String> warnings;
  final Map<String, dynamic> duplicate;
  final String? error;
  bool selected;
  bool reviewed = false;

  ExpenseBatchPreviewItem({
    required this.id,
    required this.tempId,
    required this.fileName,
    required this.status,
    required this.prediction,
    required this.confidence,
    required this.warnings,
    required this.duplicate,
    this.error,
    required this.selected,
  });

  bool get isDuplicate =>
      status == 'duplicate' || duplicate['isDuplicate'] == true;
  bool get isFailed => status == 'failed';
  bool get canSelect => !isDuplicate && !isFailed;
  bool get needsReview => status == 'needs_review';

  factory ExpenseBatchPreviewItem.fromMap(
    Map<String, dynamic> raw,
    int index,
  ) {
    final status = expenseBatchJobText(raw['status']).toLowerCase();
    final duplicate = raw['duplicate'] is Map
        ? Map<String, dynamic>.from(raw['duplicate'] as Map)
        : <String, dynamic>{};
    final tempId = expenseBatchJobText(raw['tempId']);
    final fileName = expenseBatchJobFirstText([
      raw['fileName'],
      raw['sourceDocument'] is Map
          ? (raw['sourceDocument'] as Map)['fileName']
          : null,
      'Documento ${index + 1}',
    ]);
    final isDuplicate =
        status == 'duplicate' || duplicate['isDuplicate'] == true;
    final isFailed = status == 'failed';
    return ExpenseBatchPreviewItem(
      id: tempId.isNotEmpty ? tempId : '${fileName}_$index',
      tempId: tempId,
      fileName: fileName,
      status: status.isEmpty ? 'needs_review' : status,
      prediction: raw['prediction'] is Map
          ? Map<String, dynamic>.from(raw['prediction'] as Map)
          : <String, dynamic>{},
      confidence: raw['confidence'] is Map
          ? Map<String, dynamic>.from(raw['confidence'] as Map)
          : <String, dynamic>{},
      warnings: expenseBatchStringList(raw['warnings']),
      duplicate: duplicate,
      error: expenseBatchJobFirstText([
        raw['error'],
        raw['message'],
        raw['reason'],
      ]),
      selected: status == 'ready' && !isDuplicate && !isFailed,
    );
  }
}

String expenseBatchJobText(dynamic value) => value?.toString().trim() ?? '';

String expenseBatchJobFirstText(Iterable<dynamic> values) {
  for (final value in values) {
    final text = expenseBatchJobText(value);
    if (text.isNotEmpty) return text;
  }
  return '';
}

int expenseBatchJobInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(expenseBatchJobText(value)) ?? 0;
}

double expenseBatchJobDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(expenseBatchJobText(value)) ?? 0;
}

bool isExpenseBatchIncidentStatus(String status) {
  return const {
    'failed',
    'needs_review',
    'duplicate',
    'duplicated',
    'skipped',
    'validation_error',
  }.contains(status.trim().toLowerCase());
}

bool hasExpenseBatchIncidentItems(
  Iterable<ExpenseBatchPreviewItem> items, {
  int skippedCount = 0,
  int duplicateCount = 0,
  int failedCount = 0,
  int warningCount = 0,
}) {
  return items.any((item) => isExpenseBatchIncidentStatus(item.status)) ||
      skippedCount > 0 ||
      duplicateCount > 0 ||
      failedCount > 0 ||
      warningCount > 0;
}

List<String> expenseBatchStringList(dynamic value) {
  if (value is List) {
    return value
        .map((entry) => expenseBatchJobText(entry))
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  final text = expenseBatchJobText(value);
  return text.isEmpty ? <String>[] : <String>[text];
}

List<ExpenseBatchPreviewItem> expenseBatchPreviewItemsFromPayload(
  Map<String, dynamic>? payload,
) {
  final rawItems = payload?['items'];
  if (rawItems is! List) return <ExpenseBatchPreviewItem>[];
  return [
    for (var index = 0; index < rawItems.length; index++)
      if (rawItems[index] is Map)
        ExpenseBatchPreviewItem.fromMap(
          Map<String, dynamic>.from(rawItems[index] as Map),
          index,
        ),
  ];
}

String expenseBatchJobStatusFromPayload(Map<String, dynamic>? payload) {
  final status = expenseBatchJobText(payload?['status']).toLowerCase();
  if (status.isEmpty) return 'idle';
  return status;
}

bool isExpenseBatchJobTerminal(String? status) =>
    status == 'completed' ||
    status == 'failed' ||
    status == 'needs_review' ||
    status == 'cancelled';

String expenseBatchJobMessageFromPayload(Map<String, dynamic>? payload) {
  if (payload == null) return '';
  return expenseBatchJobFirstText([
    payload['message'],
    payload['detail'],
    payload['currentStep'],
    payload['status'],
  ]);
}

String expenseBatchJobUiMessage(Map<String, dynamic>? payload) {
  final status = expenseBatchJobStatusFromPayload(payload);
  final backendMessage = expenseBatchJobMessageFromPayload(payload);
  final processedFiles = expenseBatchJobInt(payload?['processedFiles']);
  final totalFiles = expenseBatchJobInt(payload?['totalFiles']);

  switch (status) {
    case 'queued':
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Importacion en cola. Puedes salir de esta pantalla mientras se procesa el lote.';
    case 'processing':
      final prefix = (processedFiles > 0 && totalFiles > 0)
          ? 'Procesando $processedFiles de $totalFiles archivos.'
          : 'Procesando lote de gastos.';
      if (backendMessage.isNotEmpty) {
        return '$prefix $backendMessage';
      }
      return '$prefix Puedes salir de esta pantalla mientras se completa la importacion.';
    case 'completed':
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Importacion completada.';
    case 'failed':
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Importacion fallida.';
    default:
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Esperando importacion...';
  }
}

List<String> expenseBatchIssuesFromPayload(Map<String, dynamic>? payload) {
  if (payload == null) return const <String>[];
  final issues = <String>[];

  void append(dynamic entry, {String? fallbackReason}) {
    if (entry == null) return;
    if (entry is String) {
      final text = entry.trim();
      if (text.isNotEmpty) issues.add(text);
      return;
    }
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      final fileName = expenseBatchJobFirstText([
        map['fileName'],
        map['filename'],
        map['name'],
        map['documentName'],
        map['document'],
      ]);
      final reason = expenseBatchJobFirstText([
        map['reason'],
        map['message'],
        map['error'],
        map['detail'],
        fallbackReason,
      ]);
      if (fileName.isNotEmpty && reason.isNotEmpty) {
        issues.add('$fileName - $reason');
      } else if (fileName.isNotEmpty) {
        issues.add(fileName);
      } else if (reason.isNotEmpty) {
        issues.add(reason);
      }
    }
  }

  void appendList(dynamic raw, {String? fallbackReason}) {
    if (raw is List) {
      for (final entry in raw) {
        append(entry, fallbackReason: fallbackReason);
      }
    }
  }

  appendList(payload['errors'], fallbackReason: 'Error');
  appendList(payload['issues'], fallbackReason: 'Incidencia');
  appendList(payload['warnings'], fallbackReason: 'Advertencia');
  appendList(payload['failedFiles'], fallbackReason: 'No se pudo importar');
  appendList(payload['skippedFiles'], fallbackReason: 'Se omitio del lote');
  appendList(payload['files']);

  return issues.toSet().toList();
}

Map<String, String> expenseBatchFileIssueMapFromPayload(
  Map<String, dynamic>? payload,
) {
  if (payload == null) return const <String, String>{};
  final issuesByFile = <String, String>{};

  void append(dynamic entry, {String? fallbackReason}) {
    if (entry is! Map) return;
    final map = Map<String, dynamic>.from(entry);
    final fileName = expenseBatchJobFirstText([
      map['fileName'],
      map['filename'],
      map['name'],
      map['documentName'],
      map['document'],
    ]);
    if (fileName.isEmpty) return;
    final reason = expenseBatchJobFirstText([
      map['reason'],
      map['message'],
      map['error'],
      map['detail'],
      fallbackReason,
    ]);
    issuesByFile[fileName.toLowerCase().trim()] =
        reason.isEmpty ? 'Con incidencia' : reason;
  }

  void appendList(dynamic raw, {String? fallbackReason}) {
    if (raw is List) {
      for (final entry in raw) {
        append(entry, fallbackReason: fallbackReason);
      }
    }
  }

  appendList(payload['failedFiles'], fallbackReason: 'No se pudo importar');
  appendList(payload['skippedFiles'], fallbackReason: 'Se omitio del lote');
  appendList(payload['errors'], fallbackReason: 'Error');
  appendList(payload['issues'], fallbackReason: 'Incidencia');
  appendList(payload['files']);

  return issuesByFile;
}
