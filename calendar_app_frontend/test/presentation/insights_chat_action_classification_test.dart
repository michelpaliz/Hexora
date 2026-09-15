import 'package:hexora/presentation/features/shared/widgets/insights_chat_action_classification.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';
import 'package:test/test.dart';

void main() {
  test('matches the two exact action tokens after trimming', () {
    expect(
      isInsightsIncomeInvoicesByAmountAction(
        ' __menu__:category_income:facturas_por_importe ',
      ),
      isTrue,
    );
    expect(
      isInsightsIncomeInvoicesByAmountAction(
        '__menu__:category_income:facturas_por_importes',
      ),
      isFalse,
    );
    expect(isInsightsIncomeInvoicesByAmountAction(null), isFalse);

    expect(
      isInsightsFinanceBreakdownAction(
        ' __menu__::finance_follow_up:breakdown ',
      ),
      isTrue,
    );
    expect(isInsightsFinanceBreakdownAction('finance_follow_up'), isFalse);
  });

  test('detects existing Spanish and English zero-movement phrases', () {
    for (final text in [
      'Se encontraron 0 movimiento(s)',
      'Total: 0 MOVIMIENTOS',
      'Found 0 movement(s)',
      'There are 0 MOVEMENTS',
    ]) {
      expect(insightsMessageIndicatesZeroFinanceMovements(text), isTrue);
    }
    expect(insightsMessageIndicatesZeroFinanceMovements(''), isFalse);
    expect(
      insightsMessageIndicatesZeroFinanceMovements('No matching entries'),
      isFalse,
    );
  });

  test('classifies export options by action or the existing label keywords',
      () {
    const byAction = InsightsMenuOption(
      index: 1,
      label: 'Download',
      action: '__menu__:finance:export',
    );
    const byLegacyAction = InsightsMenuOption(
      index: 2,
      label: 'Download',
      action: 'export_excel',
    );
    const byLabel = InsightsMenuOption(index: 3, label: 'Descargar Excel');
    const unrelated = InsightsMenuOption(index: 4, label: 'Open details');

    expect(isInsightsExcelExportMenuOption(byAction), isTrue);
    expect(isInsightsExcelExportMenuOption(byLegacyAction), isTrue);
    expect(isInsightsExcelExportMenuOption(byLabel), isTrue);
    expect(isInsightsExcelExportMenuOption(unrelated), isFalse);
    expect(looksLikeInsightsExcelExportOption('EXPORT report'), isTrue);
    expect(looksLikeInsightsExcelExportOption(''), isFalse);
  });
}
