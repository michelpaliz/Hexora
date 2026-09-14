import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/utils/money_format_utils.dart';

String formatMoneyValue(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return formatMoneyEu(trimmed, fallback: trimmed);
}
