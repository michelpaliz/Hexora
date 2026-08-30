import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';

const String _missingAuditValue = '—';

String? formatAuditQueryDate(DateTime? value) {
  if (value == null) return null;
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String formatAuditDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return _missingAuditValue;
  return text.length >= 10 ? text.substring(0, 10) : text;
}

String formatAuditMoney(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  return formatMoneyEu(number, fallback: _missingAuditValue);
}
