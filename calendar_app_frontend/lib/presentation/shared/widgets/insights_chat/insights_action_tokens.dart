import 'insights_chat_menu.dart';

bool looksLikeActionToken(String text) {
  final trimmed = text.trim();
  return trimmed.startsWith('__menu__:') ||
      trimmed.startsWith('__back__:') ||
      trimmed.startsWith('__anchored_') ||
      trimmed.startsWith('__') && trimmed.contains(':');
}

const String incomeInvoicesByAmountAction =
    '__menu__:category_income:facturas_por_importe';
const String linkedIncomeReviewAction =
    '__menu__:category_income:linked_income_review';
const String financeBreakdownAction = '__menu__::finance_follow_up:breakdown';

bool isIncomeInvoicesByAmountAction(String? text) {
  return (text ?? '').trim() == incomeInvoicesByAmountAction;
}

bool isFinanceBreakdownAction(String? text) {
  return (text ?? '').trim() == financeBreakdownAction;
}

bool messageIndicatesZeroFinanceMovements(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('0 movimiento(s)') ||
      normalized.contains('0 movimientos') ||
      normalized.contains('0 movement(s)') ||
      normalized.contains('0 movements');
}

bool looksLikeExcelExportOption(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('export') ||
      normalized.contains('excel') ||
      normalized.contains('descargar');
}

bool isExcelExportMenuOption(InsightsMenuOption option) {
  final action = option.action?.trim().toLowerCase() ?? '';
  return action.contains(':export') ||
      action.contains('export_excel') ||
      looksLikeExcelExportOption(option.label);
}
