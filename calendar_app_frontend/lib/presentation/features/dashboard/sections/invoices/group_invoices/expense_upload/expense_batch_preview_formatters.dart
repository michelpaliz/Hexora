import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_batch_job_models.dart';
import 'package:intl/intl.dart';

String formatExpenseBatchBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

String formatExpensePreviewMoney(dynamic value) {
  if (value == null) return '';
  if (value is num) return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return expenseBatchJobText(value);
}

double parseExpensePreviewNumber(dynamic value) {
  if (value is num) return value.toDouble();
  var text = expenseBatchJobText(value).replaceAll(
    RegExp(r'[^0-9,\.\-]'),
    '',
  );
  if (text.contains(',') && text.contains('.')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  }
  return double.tryParse(text) ?? 0;
}

String formatExpensePreviewCurrency(double value, String currency) {
  final trimmedCurrency = currency.trim().toUpperCase();
  final symbol = trimmedCurrency == 'EUR'
      ? 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬'
      : trimmedCurrency == 'USD'
          ? r'$'
          : trimmedCurrency.isEmpty
              ? ''
              : trimmedCurrency;
  final normalizedSymbol = trimmedCurrency == 'EUR' ? '€' : symbol;
  return NumberFormat.currency(
    locale: 'es_ES',
    symbol: normalizedSymbol,
    decimalDigits: 2,
  ).format(value);
}

String expensePreviewStatusLabel(ExpenseBatchPreviewItem item) {
  if (item.isDuplicate) return 'Duplicado';
  if (item.isFailed) return 'Fallido';
  if (item.needsReview) return item.reviewed ? 'Revisado' : 'Revisar';
  if (item.status == 'ready') return 'Listo';
  return item.status.isEmpty ? 'Pendiente' : item.status;
}
