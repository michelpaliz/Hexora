import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';

bool insightsMoneyColumn(Map<String, dynamic> column) {
  final type =
      (column['type'] ?? column['format'] ?? '').toString().toLowerCase();
  if (const {'currency', 'money', 'amount'}.contains(type)) return true;
  final key = (column['key'] ?? '')
      .toString()
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll('formatted', '');
  return const {
    'amount',
    'importe',
    'total',
    'subtotal',
    'tax',
    'vat',
    'iva',
    'base',
    'taxablebase',
    'netamount',
    'grossamount',
    'balance',
    'revenue',
    'income',
    'expenses',
    'paidamount',
    'pendingamount',
    'invoiceamount',
    'matchedinvoiceamount',
    'invoicetotal',
  }.contains(key);
}

String formatInsightsMoney(BuildContext context, dynamic value,
    {String? currency}) {
  if (value == null) return '';
  final raw = value.toString().trim();
  if (raw.isEmpty) return '';
  // Never turn explanatory text or an unavailable value into a monetary value.
  final codeInValue = RegExp(r'\b[A-Z]{3}\b').firstMatch(raw)?.group(0);
  final numericText = raw
      .replaceAll(RegExp(r'\b[A-Z]{3}\b'), '')
      .replaceAll(RegExp(r'[€$£¥\s\u00a0]'), '');
  if (value is! num && !RegExp(r'^\(?-?[\d.,]+\)?-?$').hasMatch(numericText)) {
    return raw;
  }
  final parsed = value is num ? value : StatementsFormatters.parseAmount(raw);
  if (parsed == null || !parsed.isFinite) return raw;
  final supplied = currency?.trim();
  final inferred = codeInValue ??
      (raw.contains('£')
          ? 'GBP'
          : raw.contains(r'$')
              ? 'USD'
              : raw.contains('¥')
                  ? 'JPY'
                  : 'EUR');
  final code = switch (supplied) {
    '€' => 'EUR',
    r'$' => 'USD',
    '£' => 'GBP',
    '¥' => 'JPY',
    null || '' => inferred,
    _ => supplied.toUpperCase(),
  };
  final locale = Localizations.localeOf(context);
  final localeName = locale.countryCode == null
      ? (locale.languageCode == 'es' ? 'es_ES' : 'en_US')
      : locale.toString();
  return NumberFormat.currency(
    locale: localeName,
    name: code,
    symbol: code == 'EUR'
        ? '€'
        : code == 'GBP'
            ? '£'
            : code,
  ).format(parsed);
}
