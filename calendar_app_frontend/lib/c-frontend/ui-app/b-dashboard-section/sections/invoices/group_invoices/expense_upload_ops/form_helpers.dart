import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:intl/intl.dart';

/// Helper functions for expense upload form operations
class ExpenseFormHelpers {
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

  /// Build lines payload for API submission
  static List<Map<String, dynamic>>? buildLinesPayload(List lines) {
    if (lines.isEmpty) return null;
    return lines
        .map((line) => line.toJson() as Map<String, dynamic>)
        .toList(growable: false);
  }

  /// Pick a file using FilePicker
  static Future<FilePickResult?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
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
      final qty = parseNum(entry['quantity']) ?? 1;
      final unitPrice = parseNum(entry['unitPrice']) ?? 0;
      final taxRate = parseNum(entry['taxRate']) ?? 0;
      final lineSubtotal =
          parseNum(entry['lineSubtotal']) ?? (qty * unitPrice);
      final lineTax =
          parseNum(entry['lineTax']) ?? (lineSubtotal * taxRate / 100);
      final lineTotal =
          parseNum(entry['lineTotal']) ?? (lineSubtotal + lineTax);
      subtotal += lineSubtotal;
      tax += lineTax;
      total += lineTotal;
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
