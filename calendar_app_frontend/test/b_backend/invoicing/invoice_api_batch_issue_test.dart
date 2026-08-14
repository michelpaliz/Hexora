import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';

void main() {
  group('InvoicesApi batch issuance', () {
    test('uses the issue-all API endpoint', () {
      final uri = InvoicesApi().buildIssueAllUri();

      expect(uri.path, '/api/invoices/issue-all');
    });

    test('parses a successful batch response', () {
      final result = InvoiceBatchIssueResult.fromJson({
        'ok': true,
        'issuedCount': 2,
        'orderedInvoiceIds': ['invoice-2', 'invoice-1'],
        'invoices': [
          {
            '_id': 'invoice-2',
            'groupId': 'group-1',
            'clientId': 'client-1',
            'invoiceNumber': '2026-2',
            'status': 'issued',
          },
          {
            '_id': 'invoice-1',
            'groupId': 'group-1',
            'clientId': 'client-1',
            'invoiceNumber': '2026-1',
            'status': 'issued',
          },
        ],
      });

      expect(result.ok, isTrue);
      expect(result.issuedCount, 2);
      expect(result.orderedInvoiceIds, ['invoice-2', 'invoice-1']);
      expect(result.invoices.map((invoice) => invoice.id),
          ['invoice-2', 'invoice-1']);
    });

    test('parses partial-failure details', () {
      final failure = InvoiceBatchIssueFailure.fromJson({
        'message': 'Chronological issuance conflict',
        'failedInvoiceId': 'invoice-2',
        'orderedInvoiceIds': ['invoice-1', 'invoice-2'],
        'issuedInvoices': [
          {
            '_id': 'invoice-1',
            'groupId': 'group-1',
            'clientId': 'client-1',
            'invoiceNumber': '2026-1',
            'status': 'issued',
          },
        ],
        'missingInvoiceIds': ['invoice-3'],
        'nonDraftInvoiceIds': ['invoice-4'],
      });

      expect(failure.message, 'Chronological issuance conflict');
      expect(failure.failedInvoiceId, 'invoice-2');
      expect(failure.issuedCount, 1);
      expect(failure.orderedInvoiceIds, ['invoice-1', 'invoice-2']);
      expect(failure.missingInvoiceIds, ['invoice-3']);
      expect(failure.nonDraftInvoiceIds, ['invoice-4']);
    });
  });
}
