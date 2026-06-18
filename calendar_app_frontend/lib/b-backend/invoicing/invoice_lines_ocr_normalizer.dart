import 'dart:math' as math;

import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_models.dart';

double _finiteNum(dynamic value, double fallback) {
  if (value is num) {
    final v = value.toDouble();
    if (v.isFinite) return v;
  }
  if (value is String) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return fallback;
}

int _finiteInt(dynamic value, int fallback) {
  if (value is num) {
    final n = value.toInt();
    if (n.isFinite && n > 0) return n;
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) return parsed;
  }
  return fallback;
}

OcrExtractedLineDraft normalizeExtractedLine(
  dynamic raw,
  int index,
) {
  final source =
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  final lineNumber = index + 1;

  final position = _finiteInt(source['position'], lineNumber);

  final rawDescription = (source['description'] ?? '').toString().trim();
  final description =
      rawDescription.isEmpty ? 'Linea OCR $lineNumber' : rawDescription;
  final rawConceptItems = source['conceptItems'];
  final sku = cleanInvoiceText(source['sku']?.toString());
  final conceptItems = cleanInvoiceConceptItems(
    rawConceptItems is List
        ? rawConceptItems.map((item) => item.toString()).toList()
        : null,
    staleSku: sku,
  );
  final conceptTitle = invoiceConceptTitleFrom(
    conceptTitle: source['conceptTitle']?.toString(),
    sku: sku,
  );

  final quantity = math.max(_finiteNum(source['quantity'], 1), 1).toDouble();
  final unitPrice = math.max(_finiteNum(source['unitPrice'], 0), 0).toDouble();
  final taxRate = math.max(_finiteNum(source['taxRate'], 21), 0).toDouble();

  final subtotal = quantity * unitPrice;
  final lineTax = subtotal * (taxRate / 100);
  final total = subtotal + lineTax;

  return OcrExtractedLineDraft(
    position: position,
    description: description,
    quantity: quantity,
    unitPrice: unitPrice,
    taxRate: taxRate,
    lineSubtotal: subtotal,
    lineTax: lineTax,
    lineTotal: total,
    sourceText: (source['sourceText'] ?? '').toString(),
    conceptTitle: conceptTitle,
    conceptItems: conceptItems,
    serviceDate: cleanInvoiceServiceDate(source['serviceDate']),
    isCompositeConcept: source['isCompositeConcept'] is bool
        ? source['isCompositeConcept'] as bool
        : (conceptItems?.length ?? 0) > 1
            ? true
            : null,
    parseMethod: cleanInvoiceText(source['parseMethod']?.toString()),
  );
}

OcrExtractResponse normalizeExtractResponse(dynamic response) {
  final map = response is Map
      ? Map<String, dynamic>.from(response)
      : <String, dynamic>{};
  final draftRaw = map['draftLines'] ?? map['lines'];
  final draftList = draftRaw is List ? draftRaw : const <dynamic>[];
  final normalizedLines = <OcrExtractedLineDraft>[];
  for (var i = 0; i < draftList.length; i++) {
    normalizedLines.add(normalizeExtractedLine(draftList[i], i));
  }

  final confidenceValue = map['confidence'];
  double? confidence;
  if (confidenceValue is num) {
    final c = confidenceValue.toDouble();
    if (c.isFinite) confidence = c;
  }

  final warningsRaw = map['warnings'];
  final warnings = warningsRaw is List
      ? warningsRaw
          .where((e) => e != null)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty && e.trim().toLowerCase() != 'null')
          .toList()
      : const <String>[];

  final diagnosticsRaw = map['diagnostics'];
  final diagnostics = <String>[
    if (diagnosticsRaw is List)
      ...diagnosticsRaw
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty),
    if (diagnosticsRaw is Map)
      ...diagnosticsRaw.entries
          .map((e) => '${e.key}: ${e.value}')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty),
    if (diagnosticsRaw is String && diagnosticsRaw.trim().isNotEmpty)
      diagnosticsRaw.trim(),
  ];

  return OcrExtractResponse(
    ok: map['ok'] == true,
    invoiceId: (map['invoiceId'] ?? '').toString(),
    confidence: confidence,
    draftLines: normalizedLines,
    lineCount: normalizedLines.length,
    rawText: (map['rawText'] ?? '').toString(),
    warnings: warnings,
    methodUsed:
        (map['methodUsed'] ?? map['method'] ?? '').toString().trim().isEmpty
            ? null
            : (map['methodUsed'] ?? map['method']).toString().trim(),
    diagnostics: diagnostics,
  );
}
