import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String seriesId(Map<String, dynamic> series) {
  final raw = series['id'] ?? series['_id'] ?? '';
  if (raw is Map) {
    final oid = raw[r'$oid'];
    if (oid != null) return oid.toString();
  }
  return raw.toString();
}

String recurringInvoiceDateModeFrom(Map<String, dynamic> source) {
  final raw = source['invoiceDateMode'] ?? source['invoice_date_mode'];
  final value = (raw ?? '').toString().trim();
  if (value == 'fixed_day' || value == 'offset_days') return value;
  return 'execution_day';
}

String recurringInvoiceDateClampPolicyFrom(Map<String, dynamic> source) {
  final raw =
      source['invoiceDateClampPolicy'] ?? source['invoice_date_clamp_policy'];
  final value = (raw ?? '').toString().trim();
  if (value == 'error') return value;
  return 'end_of_month';
}

int? recurringInvoiceDateDayFrom(Map<String, dynamic> source) {
  final raw = source['invoiceDateDay'] ?? source['invoice_date_day'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}

int? recurringInvoiceDateOffsetDaysFrom(Map<String, dynamic> source) {
  final raw =
      source['invoiceDateOffsetDays'] ?? source['invoice_date_offset_days'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}

String recurringIssueDatePolicySummary(
  Map<String, dynamic> source,
  AppLocalizations l,
) {
  final mode = recurringInvoiceDateModeFrom(source);
  final clamp = recurringInvoiceDateClampPolicyFrom(source);
  final day = recurringInvoiceDateDayFrom(source);
  final offset = recurringInvoiceDateOffsetDaysFrom(source);
  final isEs = l.localeName.toLowerCase().startsWith('es');
  if (mode == 'fixed_day') {
    final d = (day ?? 1).toString();
    final clampLabel = clamp == 'error'
        ? (isEs ? 'error' : 'error')
        : (isEs ? 'fin de mes' : 'end of month');
    return isEs
        ? 'Dia fijo $d (ajuste: $clampLabel)'
        : 'Issue date day $d (clamp: $clampLabel)';
  }
  if (mode == 'offset_days') {
    final n = offset ?? 0;
    final sign = n >= 0 ? '+' : '';
    return isEs
        ? 'Fecha ejecucion $sign$n dia(s)'
        : 'Issue date = execution date $sign$n day(s)';
  }
  return isEs
      ? 'Misma fecha de ejecucion'
      : 'Issue date = execution day';
}

String seriesTotal(BuildContext context, Map<String, dynamic> series) {
  final l = AppLocalizations.of(context)!;
  final currency = (series['currency'] ?? 'EUR').toString();
  final format = NumberFormat.currency(locale: l.localeName, symbol: currency);
  final totals = series['totals'];
  num? total;
  if (totals is Map && totals['total'] is num) {
    total = totals['total'] as num;
  } else if (series['grandTotal'] is num) {
    total = series['grandTotal'] as num;
  } else if (series['total'] is num) {
    total = series['total'] as num;
  }
  if (total == null) return format.format(0);
  return format.format(total);
}

List<LineDraft> buildLineDrafts(
  Map<String, dynamic> series, {
  int defaultTaxRate = 21,
}) {
  final raw = series['lines'] ?? series['templateLines'];
  if (raw is List) {
    int pos = 1;
    return raw.map((item) {
      if (item is! Map) {
        return LineDraft(position: pos++);
      }
      final line = LineDraft(position: pos++);
      line.description.text = (item['description'] ?? '').toString();
      line.quantityCtrl.text = (item['quantity'] ?? '1').toString();
      line.unitPriceCtrl.text = (item['unitPrice'] ?? '').toString();
      line.taxRateCtrl.text = (item['taxRate'] ?? defaultTaxRate).toString();
      return line;
    }).toList();
  }
  return [LineDraft(position: 1)];
}

Future<void> previewSeries(
  BuildContext context,
  Map<String, dynamic> series,
  RecurringInvoicesApi api,
) async {
  Map<String, dynamic>? rule;
  final rawRule = series['rule'];
  if (rawRule is Map) {
    rule = Map<String, dynamic>.from(rawRule);
  } else {
    rule = {
      'frequency': canonicalFrequencyForApi(series['frequency']?.toString() ?? series['freq']?.toString()),
      'interval': series['interval'],
      'startDate': series['startDate'],
      'endDate': series['endDate'],
      'count': series['count'],
      'timeOfDay': series['timeOfDay'],
      'timezone': series['timezone'],
      'billDay': series['billDay'],
      'exceptions': series['exceptions'],
    };
  }
  if (rule.isEmpty) return;
  final normalizedFrequency = canonicalFrequencyForApi(
    (rule['frequency'] ?? rule['freq'] ?? series['frequency'] ?? series['freq'])
        .toString(),
  );
  String? normalizedStartDate;
  final rawStart = rule['startDate'] ??
      rule['start_date'] ??
      series['startDate'] ??
      series['start_date'];
  if (rawStart != null) {
    if (rawStart is String && rawStart.trim().isNotEmpty) {
      normalizedStartDate = rawStart.trim();
    } else {
      final parsed = parseDate(rawStart);
      if (parsed != null) {
        normalizedStartDate = DateFormat('yyyy-MM-dd').format(parsed);
      }
    }
  }
  rule['frequency'] = normalizedFrequency;
  rule['freq'] = normalizedFrequency;
  if (normalizedStartDate != null && normalizedStartDate.isNotEmpty) {
    rule['startDate'] = normalizedStartDate;
  }
  try {
    num parseNum(dynamic raw) {
      if (raw == null) return 0;
      if (raw is num) return raw;
      return num.tryParse(raw.toString().trim().replaceAll(',', '.')) ?? 0;
    }
    final discountAmount = parseNum(series['discountAmount']);
    final discountPercent = parseNum(series['discountPercent']).clamp(0, 100);
    final rawLines = series['lines'] ?? series['templateLines'];
    final payload = <String, dynamic>{
      'rule': rule,
      // Required by recurring-receipts preview endpoint.
      'frequency': normalizedFrequency,
      'freq': normalizedFrequency,
      if ((rule['startDate'] ?? '').toString().trim().isNotEmpty)
        'startDate': rule['startDate'],
      if (rule['interval'] != null) 'interval': rule['interval'],
      if (rule['timeOfDay'] != null) 'timeOfDay': rule['timeOfDay'],
      if (rule['timezone'] != null) 'timezone': rule['timezone'],
      if (rule['billDay'] != null) 'billDay': rule['billDay'],
      if (rule['endDate'] != null) 'endDate': rule['endDate'],
      if (rule['count'] != null) 'count': rule['count'],
      if (rule['exceptions'] != null) 'exceptions': rule['exceptions'],
      'invoiceDateMode': recurringInvoiceDateModeFrom(series),
      'invoiceDateClampPolicy': recurringInvoiceDateClampPolicyFrom(series),
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      if (rawLines is List) 'lines': rawLines,
      if (series['totals'] is Map) 'totals': series['totals'],
    };
    final day = recurringInvoiceDateDayFrom(series);
    if (day != null) payload['invoiceDateDay'] = day;
    final offset = recurringInvoiceDateOffsetDaysFrom(series);
    if (offset != null) payload['invoiceDateOffsetDays'] = offset;

    final result = await api.preview(payload);
    final rows = <String>[];
    final rawItems = result['items'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final exec = (item['executionAt'] ?? item['execution_at'] ?? '-')
            .toString();
        final issue = (item['issueDate'] ?? item['issue_date'] ?? '-')
            .toString();
        final err = (item['error'] ?? '').toString().trim();
        rows.add(
          err.isNotEmpty ? '- $exec -> $issue ($err)' : '- $exec -> $issue',
        );
      }
    }
    if (rows.isEmpty) {
      final dates =
          (result['dates'] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[];
      rows.addAll(dates.map((d) => '- $d'));
    }
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.recurringInvoicesPreviewTitle),
        content: SizedBox(
          width: 420,
          child: rows.isEmpty
              ? Text(l.recurringInvoicesPreviewDialogEmpty)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: rows
                      .take(12)
                      .map((d) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(d),
                          ))
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

