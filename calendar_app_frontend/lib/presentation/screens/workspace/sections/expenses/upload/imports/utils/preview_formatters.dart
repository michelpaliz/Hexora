part of '../../expense_upload_screen.dart';

String _formatBatchBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

String _expensePreviewMoney(dynamic value) {
  if (value == null) return '';
  if (value is num) return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return _batchJobText(value);
}

double _expensePreviewNumber(dynamic value) {
  if (value is num) return value.toDouble();
  var text = _batchJobText(value).replaceAll(RegExp(r'[^0-9,\.\-]'), '');
  if (text.contains(',') && text.contains('.')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  }
  return double.tryParse(text) ?? 0;
}

String _expensePreviewCurrency(double value, String currency) {
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

String _expensePreviewStatusLabel(_ExpenseBatchPreviewItem item) {
  if (item.isDuplicate) return 'Duplicado';
  if (item.isFailed) return 'Fallido';
  if (item.needsReview) return item.reviewed ? 'Revisado' : 'Revisar';
  if (item.status == 'ready') return 'Listo';
  return item.status.isEmpty ? 'Pendiente' : item.status;
}

IconData _expensePreviewStatusIcon(_ExpenseBatchPreviewItem item) {
  if (item.isDuplicate) return Icons.content_copy_outlined;
  if (item.isFailed) return Icons.error_outline;
  if (item.needsReview && !item.reviewed) return Icons.rate_review_outlined;
  if (item.status == 'ready' || item.reviewed) {
    return Icons.verified_outlined;
  }
  return Icons.hourglass_empty_rounded;
}

Color _expensePreviewStatusColor(
  _ExpenseBatchPreviewItem item,
  ColorScheme cs,
) {
  if (item.isDuplicate || item.isFailed) return cs.error;
  if (item.needsReview && !item.reviewed) return Colors.amber.shade700;
  if (item.status == 'ready' || item.reviewed) return Colors.green.shade600;
  return cs.onSurfaceVariant;
}

Color _expensePreviewConfidenceColor(double confidence, ColorScheme cs) {
  if (confidence <= 0) return cs.onSurfaceVariant;
  if (confidence >= 0.86) return Colors.green.shade600;
  if (confidence >= 0.72) return Colors.amber.shade700;
  return cs.error;
}
