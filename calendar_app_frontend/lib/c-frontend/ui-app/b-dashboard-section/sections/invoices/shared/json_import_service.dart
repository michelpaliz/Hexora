import 'dart:convert';

import 'package:hexora/l10n/app_localizations.dart';

enum JsonImportEntityType { invoice, receipt, presupuesto }

class JsonImportService {
  static bool isValidJsonObjectOrArray(String sourceText) {
    final decoded = _tryDecode(sourceText.trim());
    return decoded is Map || decoded is List;
  }

  static String? repairJsonText(String sourceText) {
    final raw = sourceText.trim();
    if (raw.isEmpty) return null;

    final attempts = <String>[];

    void addAttempt(String candidate) {
      final value = candidate.trim();
      if (value.isEmpty) return;
      if (!attempts.contains(value)) {
        attempts.add(value);
      }
    }

    String normalizeBasic(String input) {
      return input
          .replaceAll('\u201c', '"')
          .replaceAll('\u201d', '"')
          .replaceAll('\u2018', "'")
          .replaceAll('\u2019', "'");
    }

    addAttempt(normalizeBasic(raw));
    addAttempt(_stripMarkdownCodeFences(normalizeBasic(raw)));
    addAttempt(_escapeLikelyInnerQuotes(_stripMarkdownCodeFences(normalizeBasic(raw))));

    for (final base in List<String>.from(attempts)) {
      final trimmedNoise = _trimWrapperNoise(base);
      addAttempt(trimmedNoise);
      addAttempt(_escapeLikelyInnerQuotes(trimmedNoise));

      final firstBrace = trimmedNoise.indexOf('{');
      final lastBrace = trimmedNoise.lastIndexOf('}');
      if (firstBrace >= 0 && lastBrace > firstBrace) {
        addAttempt(trimmedNoise.substring(firstBrace, lastBrace + 1));
        addAttempt(_escapeLikelyInnerQuotes(
          trimmedNoise.substring(firstBrace, lastBrace + 1),
        ));
      }

      final firstBracket = trimmedNoise.indexOf('[');
      final lastBracket = trimmedNoise.lastIndexOf(']');
      if (firstBracket >= 0 && lastBracket > firstBracket) {
        addAttempt(trimmedNoise.substring(firstBracket, lastBracket + 1));
        addAttempt(_escapeLikelyInnerQuotes(
          trimmedNoise.substring(firstBracket, lastBracket + 1),
        ));
      }

      if (!trimmedNoise.startsWith('{') &&
          trimmedNoise.contains('"draftLines"')) {
        addAttempt('{$trimmedNoise}');
      }
      if (!trimmedNoise.startsWith('{') && trimmedNoise.contains('"lines"')) {
        addAttempt('{$trimmedNoise}');
      }

      if (_looksLikeObjectSequence(trimmedNoise)) {
        addAttempt('[$trimmedNoise]');
        addAttempt('{"draftLines":[$trimmedNoise]}');
      }

      if (trimmedNoise.startsWith('[') && trimmedNoise.endsWith(']')) {
        addAttempt('{"draftLines":$trimmedNoise}');
      }

      if (trimmedNoise.startsWith('{') && trimmedNoise.endsWith('}')) {
        final decoded = _tryDecode(trimmedNoise);
        if (decoded is Map &&
            !_containsImportRoot(decoded) &&
            _looksLikeLineObject(decoded)) {
          addAttempt('{"draftLines":[$trimmedNoise]}');
        }
      }
    }

    for (final candidate in attempts) {
      final decoded = _tryDecode(candidate);
      if (decoded is Map || decoded is List) {
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      if (decoded is String) {
        final nested = repairJsonText(decoded);
        if (nested != null) return nested;
      }
    }
    return null;
  }

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

  static dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static String _stripMarkdownCodeFences(String input) {
    final lines = input.split('\n');
    final filtered = lines
        .where((line) => !line.trimLeft().startsWith('```'))
        .join('\n')
        .trim();
    return filtered.isEmpty ? input.trim() : filtered;
  }

  static String _trimWrapperNoise(String input) {
    var value = input.trim();
    var changed = true;
    while (changed && value.isNotEmpty) {
      changed = false;
      if (value.endsWith(';')) {
        value = value.substring(0, value.length - 1).trimRight();
        changed = true;
      }
      if (value.startsWith('(') && value.endsWith(')')) {
        value = value.substring(1, value.length - 1).trim();
        changed = true;
      }
      if (value.startsWith('`') && value.endsWith('`')) {
        value = value.substring(1, value.length - 1).trim();
        changed = true;
      }
    }
    return value;
  }

  static bool _looksLikeObjectSequence(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) return false;
    return trimmed.contains('},{') ||
        trimmed.contains('"description"') ||
        trimmed.contains('"quantity"') ||
        trimmed.contains('"qty"') ||
        trimmed.contains('"unitPrice"') ||
        trimmed.contains('"price"') ||
        trimmed.contains('"taxRate"') ||
        trimmed.contains('"vatRate"');
  }

  static bool _containsImportRoot(Map<dynamic, dynamic> map) {
    return map['draftLines'] is List ||
        map['lines'] is List ||
        map['blocks'] is List;
  }

  static bool _looksLikeLineObject(Map<dynamic, dynamic> map) {
    final keys = map.keys.map((e) => e.toString().trim().toLowerCase()).toSet();
    return keys.contains('description') ||
        keys.contains('concepttitle') ||
        keys.contains('title') ||
        keys.contains('quantity') ||
        keys.contains('qty') ||
        keys.contains('unitprice') ||
        keys.contains('price') ||
        keys.contains('taxrate') ||
        keys.contains('vatrate');
  }

  static String _escapeLikelyInnerQuotes(String input) {
    final out = StringBuffer();
    var inString = false;
    var escaping = false;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        if (ch == '"') {
          inString = true;
        }
        out.write(ch);
        continue;
      }

      if (escaping) {
        out.write(ch);
        escaping = false;
        continue;
      }

      if (ch == r'\') {
        out.write(ch);
        escaping = true;
        continue;
      }

      if (ch == '"') {
        final next = _nextNonWhitespaceChar(input, i + 1);
        final isClosingQuote = next == null ||
            next == ':' ||
            next == ',' ||
            next == '}' ||
            next == ']';

        if (isClosingQuote) {
          inString = false;
          out.write(ch);
        } else {
          out.write(r'\"');
        }
        continue;
      }

      out.write(ch);
    }

    return out.toString();
  }

  static String? _nextNonWhitespaceChar(String input, int start) {
    for (var i = start; i < input.length; i++) {
      final ch = input[i];
      if (ch.trim().isNotEmpty) return ch;
    }
    return null;
  }
}
