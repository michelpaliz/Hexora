import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatementsFormatters {
  static String formatDate(BuildContext context, dynamic value) {
    final locale = _resolveLocale(context);
    final dt = _parseDateValue(value, locale);
    if (dt == null) return value?.toString() ?? '';
    final local = dt.toLocal();
    return DateFormat.yMd(locale).format(local);
  }

  static String formatDateTime(
    BuildContext context,
    dynamic value, {
    bool includeTime = true,
  }) {
    final locale = _resolveLocale(context);
    final dt = _parseDateValue(value, locale);
    if (dt == null) return value?.toString() ?? '';
    final local = dt.toLocal();
    final date = DateFormat.yMd(locale).format(local);
    if (!includeTime) return date;
    final time = DateFormat.Hm(locale).format(local);
    return '$date • $time';
  }

  static String formatAmount(
    BuildContext context,
    dynamic value, {
    int minFractionDigits = 2,
    int maxFractionDigits = 2,
  }) {
    final num? parsed = _tryParseNum(value);
    if (parsed == null) return value?.toString() ?? '';
    final locale = _resolveLocale(context);
    final formatter = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = minFractionDigits
      ..maximumFractionDigits = maxFractionDigits;
    return formatter.format(parsed);
  }

  static String formatCount(BuildContext context, dynamic value) {
    final num? parsed = _tryParseNum(value);
    if (parsed == null) return value?.toString() ?? '';
    final locale = _resolveLocale(context);
    final formatter = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 0;
    return formatter.format(parsed);
  }

  static String formatCurrency(BuildContext context, dynamic value) {
    final num? parsed = _tryParseNum(value);
    if (parsed == null) return value?.toString() ?? '';
    final locale = _resolveLocale(context);
    final symbol = locale.startsWith('es') ? '€' : '';
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(parsed);
  }

  static num? parseAmount(dynamic value) => _tryParseNum(value);

  static String _resolveLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final country = locale.countryCode;
    if (country != null && country.isNotEmpty) {
      return '${lang}_$country';
    }
    if (lang == 'es') return 'es_ES';
    if (lang == 'en') return 'en_US';
    return lang;
  }

  static num? _tryParseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    var raw = value.toString().trim();
    if (raw.isEmpty) return null;
    var negative = false;
    if (raw.startsWith('(') && raw.endsWith(')')) {
      negative = true;
      raw = raw.substring(1, raw.length - 1).trim();
    }
    if (raw.endsWith('-')) {
      negative = true;
      raw = raw.substring(0, raw.length - 1).trim();
    }
    raw = raw.replaceAll(RegExp(r'[^0-9,.\- ]'), '');
    raw = raw.replaceAll(RegExp(r'(?<!^)-'), '');
    final normalized = _normalizeNumberString(raw);
    final parsed = num.tryParse(normalized);
    if (parsed == null) return null;
    if (negative && parsed > 0) return -parsed;
    return parsed;
  }

  static String _normalizeNumberString(String raw) {
    final hasComma = raw.contains(',');
    final hasDot = raw.contains('.');
    if (hasComma && hasDot) {
      final lastComma = raw.lastIndexOf(',');
      final lastDot = raw.lastIndexOf('.');
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final groupingSep = decimalSep == ',' ? '.' : ',';
      return raw
          .replaceAll(groupingSep, '')
          .replaceAll(decimalSep, '.')
          .replaceAll(' ', '');
    }
    if (hasComma) {
      return _normalizeSingleSeparator(raw, ',');
    }
    if (hasDot) {
      return _normalizeSingleSeparator(raw, '.');
    }
    return raw;
  }

  static String _normalizeSingleSeparator(String raw, String sep) {
    final trimmed = raw.replaceAll(' ', '');
    final isNegative = trimmed.startsWith('-');
    final unsigned = isNegative ? trimmed.substring(1) : trimmed;
    final parts = unsigned.split(sep);
    if (parts.length == 2) {
      if (parts[1].length == 3) {
        final normalized = unsigned.replaceAll(sep, '');
        return isNegative ? '-$normalized' : normalized;
      }
      if (parts[1].length <= 3) {
        final normalized = '${parts[0]}.${parts[1]}';
        return isNegative ? '-$normalized' : normalized;
      }
      final extraDecimals = parts[1].length - 3;
      if (extraDecimals > 0) {
        final digits = parts.join();
        if (digits.length > extraDecimals) {
          final splitAt = digits.length - extraDecimals;
          final normalized =
              '${digits.substring(0, splitAt)}.${digits.substring(splitAt)}';
          return isNegative ? '-$normalized' : normalized;
        }
      }
    }
    final normalized = unsigned.replaceAll(sep, '');
    return isNegative ? '-$normalized' : normalized;
  }

  static DateTime? _dateFromEpoch(int? epoch) {
    if (epoch == null) return null;
    if (epoch.abs() < 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
  }

  static DateTime? _tryParseDate(String raw, String locale) {
    final useMonthFirst = locale.startsWith('en');
    final monthFirst = [
      'M/d/yyyy',
      'M/d/yy',
      'MM/dd/yyyy',
      'MM/dd/yy',
    ];
    final dayFirst = [
      'd/M/yyyy',
      'd/M/yy',
      'dd/MM/yyyy',
      'dd/MM/yy',
    ];
    final shared = [
      'yyyy/M/d',
      'yyyy-MM-dd',
      'yyyy.MM.dd',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'MM-dd-yyyy',
      'MM.dd.yyyy',
      'yyyyMMdd',
    ];
    final patterns = <String>[
      ...(useMonthFirst ? monthFirst : dayFirst),
      ...shared,
      ...(useMonthFirst ? dayFirst : monthFirst),
    ];
    for (final pattern in patterns) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  static DateTime? _parseDateValue(dynamic value, String locale) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return _dateFromEpoch(value);
    if (value is double) return _dateFromEpoch(value.round());
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(raw)) {
      final epoch = int.tryParse(raw);
      return _dateFromEpoch(epoch);
    }
    return DateTime.tryParse(raw) ?? _tryParseDate(raw, locale);
  }
}
