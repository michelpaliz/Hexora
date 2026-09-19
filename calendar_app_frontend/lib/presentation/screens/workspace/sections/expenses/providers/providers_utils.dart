import 'package:hexora/presentation/shared/utils/formatting/money_format_utils.dart';

String formatMoneyValue(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return formatMoneyEu(trimmed, fallback: trimmed);
}
