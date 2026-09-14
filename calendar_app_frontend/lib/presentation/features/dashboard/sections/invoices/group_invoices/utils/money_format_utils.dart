import 'package:intl/intl.dart';

final NumberFormat _moneyFormatEs = NumberFormat('#,##0.00', 'es_ES');

String normalizeMoneyInput(String value) {
  var raw = value.trim().replaceAll(' ', '');
  if (raw.isEmpty) return raw;
  final hasComma = raw.contains(',');
  final hasDot = raw.contains('.');
  if (hasComma && hasDot) {
    final lastComma = raw.lastIndexOf(',');
    final lastDot = raw.lastIndexOf('.');
    if (lastComma > lastDot) {
      // 1.234,56 -> 1234.56
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // 1,234.56 -> 1234.56
      raw = raw.replaceAll(',', '');
    }
  } else if (hasComma) {
    final parts = raw.split(',');
    if (parts.length == 2 && parts[1].length <= 2) {
      // 1234,56 -> 1234.56
      raw = '${parts[0]}.${parts[1]}';
    } else {
      // 1,234,567
      raw = raw.replaceAll(',', '');
    }
  }
  return raw;
}

double? parseFlexibleMoney(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final normalized = normalizeMoneyInput(value.toString());
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String formatMoneyEu(dynamic value, {String fallback = ''}) {
  final parsed = parseFlexibleMoney(value);
  if (parsed == null) return fallback;
  return _moneyFormatEs.format(parsed);
}

