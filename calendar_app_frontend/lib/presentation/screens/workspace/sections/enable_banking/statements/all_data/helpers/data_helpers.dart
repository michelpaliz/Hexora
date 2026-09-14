import 'package:intl/intl.dart';

/// Helper functions for statement data parsing and formatting
class StatementsDataHelpers {
  /// Parse year from string input
  static int? parseYear(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  /// Format date to yyyy-MM-dd string
  static String dateOnly(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  /// Parse date from string input
  static DateTime? parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  /// Extract date from statement entry
  static DateTime? entryDate(Map<String, dynamic> entry) {
    final candidates = [
      'valueDate',
      'value_date',
      'date',
      'transactionDate',
      'transaction_date',
    ];
    for (final key in candidates) {
      final raw = entry[key];
      if (raw == null) continue;
      if (raw is DateTime) return raw;
      final str = raw.toString().trim();
      if (str.isEmpty) continue;
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return parsed;
      final isoMatch = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(str);
      if (isoMatch != null) {
        final datePart = isoMatch.group(0)!;
        final withTime = DateTime.tryParse('${datePart}T00:00:00Z');
        if (withTime != null) return withTime;
      }
      final slashMatch = RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(str);
      if (slashMatch != null) {
        final day = slashMatch.group(1)!;
        final month = slashMatch.group(2)!;
        final year = slashMatch.group(3)!;
        final iso = '$year-$month-$day';
        final parsed = DateTime.tryParse(iso);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Parse amount from string input (handles commas as decimal separator)
  static double? parseAmountInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final cleaned = trimmed.replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  /// Find index in list of size options
  static int sizeIndexFor(int size, List<int> sizeOptions) {
    final direct = sizeOptions.indexOf(size);
    if (direct >= 0) return direct;
    var best = 0;
    var bestDiff = (size - sizeOptions.first).abs();
    for (var i = 1; i < sizeOptions.length; i++) {
      final diff = (size - sizeOptions[i]).abs();
      if (diff < bestDiff) {
        best = i;
        bestDiff = diff;
      }
    }
    return best;
  }
}
