import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:intl/intl.dart';

/// Helper functions for expense upload form operations
class ExpenseFormHelpers {
  static const double summaryTotalsTolerance = 0.05;

  static bool parseBoolLike(dynamic value) {
    if (value is bool) return value;
    final text = (value ?? '').toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static bool hasExplicitSummaryTotalsSource(Map<String, dynamic>? expense) {
    if (expense == null) return false;
    if (parseBoolLike(expense['useSummaryTotals'])) return true;
    final source = ((expense['taxSource'] ?? expense['totalsSource']) ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return source == 'summary';
  }

  static double effectiveDiscountFromMap(Map entry) {
    final qty = parseNum(entry['quantity'] ?? entry['qty']) ?? 1;
    final baseUnitPrice =
        parseNum(entry['baseUnitPrice'] ?? entry['unitPrice'] ?? entry['price']) ??
            0;
    final grossSubtotal = qty * baseUnitPrice;
    if (grossSubtotal <= 0) return 0;
    final discountAmount =
        parseNum(entry['discountAmount'] ?? entry['discount_amount']) ?? 0;
    if (discountAmount > 0) {
      return discountAmount.clamp(0, grossSubtotal);
    }
    final discountPercent =
        parseNum(entry['discountPercent'] ?? entry['discount_percent']) ?? 0;
    if (discountPercent > 0) {
      return (grossSubtotal * discountPercent.clamp(0, 100)) / 100;
    }
    return 0;
  }

  static Map<String, double> computeExpenseLinePreview(Map entry) {
    final qty = parseNum(entry['quantity'] ?? entry['qty']) ?? 1;
    final baseUnitPrice =
        parseNum(entry['baseUnitPrice'] ?? entry['unitPrice'] ?? entry['price']) ??
            0;
    final taxRate =
        parseNum(entry['taxRate'] ?? entry['vatRate'] ?? entry['tax_rate']) ?? 0;
    final grossSubtotal = qty * baseUnitPrice;
    final discountAmount = effectiveDiscountFromMap(entry);
    final lineSubtotal = parseNum(entry['lineSubtotal']) ??
        (grossSubtotal - discountAmount).clamp(0, double.infinity);
    final lineTax =
        parseNum(entry['lineTax']) ?? (lineSubtotal * taxRate / 100);
    final lineTotal = parseNum(entry['lineTotal']) ?? (lineSubtotal + lineTax);
    return {
      'subtotal': lineSubtotal.toDouble(),
      'tax': lineTax.toDouble(),
      'total': lineTotal.toDouble(),
      'discountAmount': discountAmount.toDouble(),
      'discountPercent': grossSubtotal <= 0
          ? 0
          : ((discountAmount / grossSubtotal) * 100).clamp(0, 100).toDouble(),
    };
  }

  /// Parse amount from string input
  static double? parseAmount(String value) =>
      parseFlexibleMoney(value);

  /// Format amount to string with 2 decimals
  static String formatAmount(double? value) =>
      value == null ? '-' : formatMoneyEu(value, fallback: '-');

  /// Parse numeric value from dynamic input
  static double? parseNum(dynamic value) {
    return parseFlexibleMoney(value);
  }

  static Map<String, dynamic> _normalizeLinePayloadEntry(dynamic line) {
    if (line is Map) {
      return Map<String, dynamic>.from(line);
    }
    final dynamic json = line.toJson();
    if (json is Map) {
      return Map<String, dynamic>.from(json);
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _summaryTotalsLinePayload(
    Map<String, dynamic> source,
  ) {
    final payload = <String, dynamic>{};
    final description = (source['description'] ??
            source['conceptTitle'] ??
            source['title'] ??
            '')
        .toString()
        .trim();
    final quantity = parseNum(source['quantity'] ?? source['qty']);
    final baseUnitPrice = parseNum(
      source['baseUnitPrice'] ?? source['unitPrice'] ?? source['price'],
    );
    final discountAmount =
        parseNum(source['discountAmount'] ?? source['discount_amount']);
    final discountPercent =
        parseNum(source['discountPercent'] ?? source['discount_percent']);

    if (description.isNotEmpty) {
      payload['description'] = description;
    }
    if (quantity != null) {
      payload['quantity'] = quantity;
    }
    if (baseUnitPrice != null) {
      payload['baseUnitPrice'] = baseUnitPrice;
    }
    if (discountAmount != null && discountAmount > 0) {
      payload['discountAmount'] = discountAmount;
    }
    if (discountPercent != null && discountPercent > 0) {
      payload['discountPercent'] = discountPercent;
    }
    // When the document VAT comes from the footer summary, we intentionally
    // omit per-line tax and derived totals so the document totals remain the
    // authoritative source.
    return payload;
  }

  /// Build lines payload for API submission
  static List<Map<String, dynamic>>? buildLinesPayload(
    List lines, {
    bool useSummaryTotals = false,
  }) {
    if (lines.isEmpty) return null;
    return lines
        .map(_normalizeLinePayloadEntry)
        .map((line) =>
            useSummaryTotals ? _summaryTotalsLinePayload(line) : line)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  /// Pick a file using FilePicker
  static Future<FilePickResult?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'jpe'],
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return null;
    return FilePickResult(
      fileName: file.name,
      fileBytes: file.bytes!,
    );
  }

  /// Preview a PDF file
  static Future<bool> previewPdf(
    BuildContext context,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pick a date using date picker
  static Future<String?> pickDate(
    BuildContext context,
    String currentValue,
  ) async {
    final initial = DateTime.tryParse(currentValue) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return null;
    return DateFormat('yyyy-MM-dd').format(picked);
  }

  /// Summarize expense lines
  static Map<String, dynamic> summarizeLines(List lines) {
    String? firstDescription;
    double subtotal = 0;
    double tax = 0;
    double total = 0;
    for (final entry in lines) {
      if (entry is! Map) continue;
      final description = entry['description']?.toString().trim() ?? '';
      if (firstDescription == null && description.isNotEmpty) {
        firstDescription = description;
      }
      final preview = computeExpenseLinePreview(entry);
      subtotal += preview['subtotal'] ?? 0;
      tax += preview['tax'] ?? 0;
      total += preview['total'] ?? 0;
    }
    final count = lines.length;
    String summary = '';
    if (firstDescription != null && firstDescription.isNotEmpty) {
      summary =
          count > 1 ? '$firstDescription +${count - 1}' : firstDescription;
    } else if (count > 0) {
      summary = '$count items';
    }
    return {
      'count': count,
      'summary': summary,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
    };
  }

  static bool nearlyEqual(
    double a,
    double b, {
    double tolerance = summaryTotalsTolerance,
  }) {
    return (a - b).abs() <= tolerance;
  }

  static String? validateSummaryTotals({
    required double? base,
    required double? tax,
    required double? total,
  }) {
    if (base == null || tax == null || total == null) {
      return 'Completa base imponible, IVA total y total del documento.';
    }
    if (base < 0) {
      return 'La base imponible no puede ser negativa.';
    }
    if (tax < 0) {
      return 'El IVA total no puede ser negativo.';
    }
    if (total < 0) {
      return 'El total del documento no puede ser negativo.';
    }
    if (!nearlyEqual(base + tax, total)) {
      return 'Revisa los totales del resumen. Base + IVA debe coincidir aproximadamente con el total.';
    }
    return null;
  }

  static List<Map<String, dynamic>>? buildSummaryVatBreakdown({
    required double? base,
    required double? tax,
  }) {
    if (base == null || tax == null) return null;
    if (base < 0 || tax < 0) return null;
    final rate = base <= 0 ? 0.0 : ((tax / base) * 100);
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'rate': rate.isFinite ? double.parse(rate.toStringAsFixed(2)) : 0,
        'base': double.parse(base.toStringAsFixed(2)),
        'tax': double.parse(tax.toStringAsFixed(2)),
      }
    ];
  }

  static bool shouldUseSummaryTotals({
    Map<String, dynamic>? expense,
    required double? storedTotal,
    required double? storedTax,
    required List<Map<String, dynamic>>? lines,
  }) {
    if (hasExplicitSummaryTotalsSource(expense)) {
      return true;
    }
    if (storedTotal == null || storedTax == null || lines == null || lines.isEmpty) {
      return false;
    }
    final summary = summarizeLines(lines);
    final lineTax = (summary['tax'] as num?)?.toDouble() ?? 0;
    final lineTotal = (summary['total'] as num?)?.toDouble() ?? 0;
    return !nearlyEqual(lineTax, storedTax) || !nearlyEqual(lineTotal, storedTotal);
  }
}

/// Result from file picker
class FilePickResult {
  final String fileName;
  final Uint8List fileBytes;

  const FilePickResult({
    required this.fileName,
    required this.fileBytes,
  });
}
