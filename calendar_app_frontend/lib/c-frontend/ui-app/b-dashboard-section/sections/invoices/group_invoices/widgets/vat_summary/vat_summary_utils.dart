import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';

double? parseVatNum(dynamic value) {
  return parseFlexibleMoney(value);
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
