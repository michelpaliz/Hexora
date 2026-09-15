import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_batch_job_models.dart';
import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_batch_preview_formatters.dart';
import 'package:test/test.dart';

void main() {
  test('formats batch byte counts with the existing thresholds', () {
    expect(formatExpenseBatchBytes(-1), '0 KB');
    expect(formatExpenseBatchBytes(1024), '1 KB');
    expect(formatExpenseBatchBytes(1024 * 1024 - 1), '1024 KB');
    expect(formatExpenseBatchBytes(1024 * 1024), '1.00 MB');
  });

  test('formats and parses permissive preview amounts', () {
    expect(formatExpensePreviewMoney(null), '');
    expect(formatExpensePreviewMoney(12), '12');
    expect(formatExpensePreviewMoney(12.5), '12.50');
    expect(formatExpensePreviewMoney('  pending  '), 'pending');

    expect(parseExpensePreviewNumber(12), 12);
    expect(parseExpensePreviewNumber('€ 1.234,56'), 1234.56);
    expect(parseExpensePreviewNumber(r'$ -12.5'), -12.5);
    expect(parseExpensePreviewNumber('unknown'), 0);
  });

  test('formats currencies and preview status labels', () {
    final eur = formatExpensePreviewCurrency(1234.5, ' eur ');
    expect(eur, contains('1.234,50'));
    expect(eur, endsWith('€'));
    expect(formatExpensePreviewCurrency(10, 'usd'), endsWith(r'$'));

    ExpenseBatchPreviewItem item(String status, {bool duplicate = false}) {
      return ExpenseBatchPreviewItem(
        id: 'id',
        tempId: '',
        fileName: 'invoice.pdf',
        status: status,
        prediction: {},
        confidence: {},
        warnings: const [],
        duplicate: {'isDuplicate': duplicate},
        selected: false,
      );
    }

    expect(expensePreviewStatusLabel(item('ready')), 'Listo');
    expect(expensePreviewStatusLabel(item('failed')), 'Fallido');
    expect(
        expensePreviewStatusLabel(item('ready', duplicate: true)), 'Duplicado');
    final review = item('needs_review');
    expect(expensePreviewStatusLabel(review), 'Revisar');
    review.reviewed = true;
    expect(expensePreviewStatusLabel(review), 'Revisado');
    expect(expensePreviewStatusLabel(item('')), 'Pendiente');
  });
}
