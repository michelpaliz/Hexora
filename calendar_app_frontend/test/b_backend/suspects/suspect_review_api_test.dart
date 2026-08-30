import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/suspects/suspect_expenses_api.dart';
import 'package:hexora/b-backend/suspects/suspect_invoices_api.dart';

void main() {
  group('suspect review API contracts', () {
    test('expense configuration preserves its flow-specific behavior', () {
      final api = SuspectExpensesApi();

      expect(api.resourceName, 'expenses');
      expect(api.totalScannedKey, 'totalExpensesScanned');
      expect(api.clearNotesWhenUnreviewed, isTrue);

      final result = api.createResult(
        data: const {'ok': true},
        requestUrl: Uri.parse('https://example.test/expenses/suspects'),
        statusCode: 200,
      );
      expect(result, isA<SuspectExpensesResult>());
      expect(result.data, const {'ok': true});
    });

    test('invoice configuration preserves its flow-specific behavior', () {
      final api = SuspectInvoicesApi();

      expect(api.resourceName, 'invoices');
      expect(api.totalScannedKey, 'totalInvoicesScanned');
      expect(api.clearNotesWhenUnreviewed, isFalse);

      final exception = api.createException(
        statusCode: 422,
        message: 'Invalid review',
        url: Uri.parse('https://example.test/invoices/1/suspicion-review'),
        method: 'PATCH',
        responseBody: '{"error":"Invalid review"}',
      );
      expect(exception, isA<SuspectInvoicesApiException>());
      expect(
        exception.toString(),
        contains('SuspectInvoicesApi (422) PATCH'),
      );
    });
  });
}
