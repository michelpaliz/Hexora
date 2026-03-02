import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';

void main() {
  group('InvoicesApi delivery endpoints', () {
    final api = InvoicesApi();

    test('buildMarkSentUri uses /mark-sent', () {
      final uri = api.buildMarkSentUri('inv_1');
      expect(uri.path, '/api/invoices/inv_1/mark-sent');
    });

    test('buildMarkUnsentUri uses /mark-unsent', () {
      final uri = api.buildMarkUnsentUri('inv_1');
      expect(uri.path, '/api/invoices/inv_1/mark-unsent');
    });
  });
}
