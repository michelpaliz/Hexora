import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/b-backend/receipts/recurring_receipts_api.dart';

void main() {
  group('Recurring series run URIs', () {
    test('targets the selected invoice series', () {
      final uri = RecurringInvoicesApi().buildRunSeriesUri('series-1');

      expect(uri.path, '/api/recurring-invoices/series-1/run');
    });

    test('targets the selected receipt series', () {
      final uri = RecurringReceiptsApi().buildRunSeriesUri('receipt-series-1');

      expect(uri.path, '/api/recurring-receipts/receipt-series-1/run');
    });
  });
}
