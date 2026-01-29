import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
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

List<LineDraft> buildLineDrafts(Map<String, dynamic> series) {
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
      line.taxRateCtrl.text = (item['taxRate'] ?? '21').toString();
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
      'frequency': series['frequency'] ?? series['freq'],
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
  try {
    final result = await api.preview({'rule': rule});
    final dates =
        (result['dates'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.recurringInvoicesPreviewTitle),
        content: SizedBox(
          width: 320,
          child: dates.isEmpty
              ? Text(l.recurringInvoicesPreviewDialogEmpty)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dates
                      .take(12)
                      .map((d) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text('• $d'),
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
