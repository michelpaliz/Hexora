import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/vat_summary/vat_summary_utils.dart';

void main() {
  group('VAT comparisons', () {
    test('formats an independent Spanish quarter comparison', () {
      expect(
        formatVatComparisonLabel(
          current: 109.2,
          previous: 100,
          previousLabel: 'T2',
        ),
        '\u2191 9,2% vs. T2',
      );
      expect(
        formatVatComparisonLabel(
          current: 75,
          previous: 100,
          previousLabel: 'T2',
        ),
        '\u2193 25,0% vs. T2',
      );
    });

    test('does not invent a percentage without a comparable previous value',
        () {
      expect(
        formatVatComparisonLabel(current: 100, previous: 0),
        isNull,
      );
      expect(
        formatVatComparisonLabel(current: 100, previous: null),
        isNull,
      );
    });

    test('uses rounded chart intervals', () {
      expect(roundedVatAxisInterval([1936, 4598]), 2000);
      expect(roundedVatAxisInterval([0, 0]), 1);
    });
  });

  group('VAT expense totals', () {
    test('uses the expense summary when the fiscal purchase total is zero', () {
      final resolved = resolveVatExpenseTotal(
        fiscalValue: 0,
        expenseSummaryValue: 7526.06,
        expenseEntriesValue: 7500,
      );

      expect(resolved.value, 7526.06);
      expect(resolved.usedExpenseFallback, isTrue);
    });

    test('uses summed expense entries when no summary total is available', () {
      final resolved = resolveVatExpenseTotal(
        fiscalValue: 0,
        expenseSummaryValue: null,
        expenseEntriesValue: 450,
      );

      expect(resolved.value, 450);
      expect(resolved.usedExpenseFallback, isTrue);
    });

    test('keeps a non-zero fiscal total authoritative', () {
      final resolved = resolveVatExpenseTotal(
        fiscalValue: 400,
        expenseSummaryValue: 450,
        expenseEntriesValue: 450,
      );

      expect(resolved.value, 400);
      expect(resolved.usedExpenseFallback, isFalse);
    });
  });
}
