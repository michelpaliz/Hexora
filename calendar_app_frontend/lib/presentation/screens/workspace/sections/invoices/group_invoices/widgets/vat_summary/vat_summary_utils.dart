import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/utils/formatting/money_format_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

double? parseVatNum(dynamic value) {
  return parseFlexibleMoney(value);
}

({double value, bool usedExpenseFallback}) resolveVatExpenseTotal({
  required dynamic fiscalValue,
  required dynamic expenseSummaryValue,
  required double expenseEntriesValue,
  double tolerance = 0.005,
}) {
  final fiscal = parseVatNum(fiscalValue);
  if (fiscal != null && fiscal.abs() > tolerance) {
    return (value: fiscal, usedExpenseFallback: false);
  }

  final expenseSummary = parseVatNum(expenseSummaryValue);
  if (expenseSummary != null && expenseSummary.abs() > tolerance) {
    return (value: expenseSummary, usedExpenseFallback: true);
  }

  if (expenseEntriesValue.abs() > tolerance) {
    return (value: expenseEntriesValue, usedExpenseFallback: true);
  }

  return (value: fiscal ?? expenseSummary ?? 0, usedExpenseFallback: false);
}

String? formatVatComparisonLabel({
  required double current,
  required double? previous,
  double? providedPercentage,
  String previousLabel = '',
}) {
  if (previous == null || previous.abs() < 0.01) return null;
  final delta =
      providedPercentage ?? ((current - previous) / previous.abs()) * 100;
  if (!delta.isFinite) return null;
  final arrow = delta > 0.004
      ? '\u2191'
      : delta < -0.004
          ? '\u2193'
          : '\u2192';
  final percentage = NumberFormat.decimalPatternDigits(
    locale: 'es_ES',
    decimalDigits: 1,
  ).format(delta.abs());
  final comparison =
      previousLabel.trim().isEmpty ? 'trim. anterior' : previousLabel.trim();
  return '$arrow $percentage% vs. $comparison';
}

double roundedVatAxisInterval(Iterable<double> values) {
  final maximum = values.fold<double>(
    0,
    (current, value) => math.max(current, value.abs()),
  );
  if (maximum <= 0) return 1;
  final rough = maximum / 4;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor());
  final normalized = rough / magnitude;
  final nice = normalized <= 1
      ? 1
      : normalized <= 2
          ? 2
          : normalized <= 5
              ? 5
              : 10;
  return (nice * magnitude).toDouble();
}

String formatVatAmount(dynamic value) {
  final parsed = parseVatNum(value);
  if (parsed == null) return value?.toString() ?? '-';
  return formatMoneyEu(parsed, fallback: '-');
}

String formatVatDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

(DateTime, DateTime) quarterRangeDates(int year, int quarter) {
  final startMonth = 1 + (quarter - 1) * 3;
  final start = DateTime(year, startMonth, 1);
  final end = DateTime(year, startMonth + 3, 0);
  return (start, end);
}

String quarterRangeLabel(
  BuildContext context, {
  required int year,
  required int quarter,
}) {
  final l = AppLocalizations.of(context)!;
  String range;
  switch (quarter) {
    case 1:
      range = l.vatSummaryQuarterRangeQ1(year.toString());
      break;
    case 2:
      range = l.vatSummaryQuarterRangeQ2(year.toString());
      break;
    case 3:
      range = l.vatSummaryQuarterRangeQ3(year.toString());
      break;
    default:
      range = l.vatSummaryQuarterRangeQ4(year.toString());
  }
  return l.vatSummaryQuarterRangeLabel(quarter.toString(), range);
}

String quarterDeadlineLabel(
  BuildContext context, {
  required int year,
  required int quarter,
}) {
  final l = AppLocalizations.of(context)!;
  switch (quarter) {
    case 1:
      return l.vatSummaryQuarterDeadlineQ1(year.toString());
    case 2:
      return l.vatSummaryQuarterDeadlineQ2(year.toString());
    case 3:
      return l.vatSummaryQuarterDeadlineQ3(year.toString());
    default:
      return l.vatSummaryQuarterDeadlineQ4((year + 1).toString());
  }
}
