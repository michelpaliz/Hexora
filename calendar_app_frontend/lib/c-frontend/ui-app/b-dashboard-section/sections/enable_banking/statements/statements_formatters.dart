import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatementsFormatters {
  static String formatDate(BuildContext context, dynamic value) {
    if (value == null) return '';
    final locale = _resolveLocale(context);
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else {
      final raw = value.toString().trim();
      if (raw.isEmpty) return '';
      dt = DateTime.tryParse(raw);
    }
    if (dt == null) return value.toString();
    final local = dt.toLocal();
    return DateFormat.yMd(locale).format(local);
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
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final normalized = _normalizeNumberString(raw);
    return num.tryParse(normalized);
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
    final parts = raw.split(sep);
    if (parts.length == 2 && parts[1].length <= 3) {
      return '${parts[0].replaceAll(sep, '')}.${parts[1]}'.replaceAll(' ', '');
    }
    return raw.replaceAll(sep, '').replaceAll(' ', '');
  }
}
