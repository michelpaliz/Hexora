import 'dart:convert';

import 'package:hexora/l10n/app_localizations.dart';

enum JsonImportEntityType { invoice, receipt, presupuesto }

class JsonImportService {
  static String extractPromptText(Map<String, dynamic> response) {
    return (response['promptTemplate'] ??
            response['prompt'] ??
            response['template'] ??
            response['text'] ??
            '')
        .toString()
        .trim();
  }

  static int extractImportedCount(Map<String, dynamic> response) {
    final candidates = <dynamic>[
      response['importedCount'],
      response['lineCount'],
      response['createdCount'],
      response['count'],
    ];
    for (final value in candidates) {
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static bool extractRepairApplied(Map<String, dynamic> response) {
    return response['repairApplied'] == true ||
        response['repair_applied'] == true;
  }

  static Map<String, dynamic> buildImportPayload({
    required JsonImportEntityType entity,
    required String sourceText,
    required bool overwrite,
    required double defaultTaxRate,
  }) {
    final trimmed = sourceText.trim();
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      decoded = null;
    }

    final normalized = _normalizeByEntity(entity: entity, decoded: decoded);
    final payload = <String, dynamic>{
      ...normalized,
      'overwrite': overwrite,
      'defaultTaxRate': defaultTaxRate,
      // If payload was malformed, let backend auto-repair from raw text.
      if (decoded == null) 'rawText': sourceText,
    };
    return payload;
  }

  static String mapErrorMessage({
    required AppLocalizations l,
    required JsonImportEntityType entity,
    required int? statusCode,
    required String backendMessage,
  }) {
    final backend = backendMessage.trim();
    if (statusCode == 400) {
      return backend.isEmpty ? l.invoiceLinesJsonImportInvalidPayload : backend;
    }
    if (statusCode == 403) return 'No permission';
    if (statusCode == 404) return 'Record not found';
    if (statusCode == 409) {
      switch (entity) {
        case JsonImportEntityType.receipt:
          return 'Only draft receipts can be updated via JSON import';
        case JsonImportEntityType.presupuesto:
          return 'Only draft presupuestos can be updated via JSON import';
        case JsonImportEntityType.invoice:
          return backend.isEmpty ? 'Line position already exists' : backend;
      }
    }
    return backend.isEmpty ? l.invoiceLinesJsonImportGenericError : backend;
  }

  static Map<String, dynamic> _normalizeByEntity({
    required JsonImportEntityType entity,
    required dynamic decoded,
  }) {
    if (decoded is List) {
      switch (entity) {
        case JsonImportEntityType.invoice:
          return {'draftLines': decoded};
        case JsonImportEntityType.receipt:
          return {'lines': decoded};
        case JsonImportEntityType.presupuesto:
          return {'lines': decoded};
      }
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      switch (entity) {
        case JsonImportEntityType.invoice:
          if (map['draftLines'] is List) {
            return {'draftLines': map['draftLines']};
          }
          if (map['lines'] is List) {
            return {'draftLines': map['lines']};
          }
          return map;
        case JsonImportEntityType.receipt:
          if (map['lines'] is List) {
            return {'lines': map['lines']};
          }
          if (map['draftLines'] is List) {
            return {'draftLines': map['draftLines']};
          }
          return map;
        case JsonImportEntityType.presupuesto:
          if (map['blocks'] is List) {
            return {'blocks': map['blocks']};
          }
          if (map['lines'] is List) {
            return {'lines': map['lines']};
          }
          if (map['draftLines'] is List) {
            return {'draftLines': map['draftLines']};
          }
          return map;
      }
    }
    return <String, dynamic>{};
  }
}
