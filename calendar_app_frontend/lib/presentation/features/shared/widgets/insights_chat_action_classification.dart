import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

const String _incomeInvoicesByAmountAction =
    '__menu__:category_income:facturas_por_importe';
const String _financeBreakdownAction = '__menu__::finance_follow_up:breakdown';

bool isInsightsIncomeInvoicesByAmountAction(String? text) {
  return (text ?? '').trim() == _incomeInvoicesByAmountAction;
}

bool isInsightsFinanceBreakdownAction(String? text) {
  return (text ?? '').trim() == _financeBreakdownAction;
}

bool insightsMessageIndicatesZeroFinanceMovements(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('0 movimiento(s)') ||
      normalized.contains('0 movimientos') ||
      normalized.contains('0 movement(s)') ||
      normalized.contains('0 movements');
}

bool looksLikeInsightsExcelExportOption(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('export') ||
      normalized.contains('excel') ||
      normalized.contains('descargar');
}

bool isInsightsExcelExportMenuOption(InsightsMenuOption option) {
  final action = option.action?.trim().toLowerCase() ?? '';
  return action.contains(':export') ||
      action.contains('export_excel') ||
      looksLikeInsightsExcelExportOption(option.label);
}
