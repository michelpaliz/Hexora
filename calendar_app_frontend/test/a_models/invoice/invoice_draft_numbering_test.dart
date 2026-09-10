import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/invoice.dart';

void main() {
  group('draft invoice numbering', () {
    test('draft create payload omits frontend numbering fields', () {
      const invoice = Invoice(
        id: '',
        invoiceNumber: '001-26',
        groupId: 'group-1',
        clientId: 'client-1',
        status: 'draft',
        sequenceNumber: 1,
        yearYY: 26,
      );

      final payload = invoice.toCreatePayload();

      expect(payload['groupId'], 'group-1');
      expect(payload['clientId'], 'client-1');
      expect(payload, isNot(contains('invoiceNumber')));
      expect(payload, isNot(contains('sequenceNumber')));
      expect(payload, isNot(contains('yearYY')));
    });

    test('drafts display a label even if legacy data has a number', () {
      const draft = Invoice(
        id: 'invoice-1',
        invoiceNumber: '001-26',
        groupId: 'group-1',
        clientId: 'client-1',
        status: 'draft',
      );

      expect(draft.displayNumber(draftLabel: 'Borrador'), 'Borrador');
    });

    test('issued invoices display the backend-assigned number', () {
      const issued = Invoice(
        id: 'invoice-1',
        invoiceNumber: '2026-42',
        groupId: 'group-1',
        clientId: 'client-1',
        status: 'issued',
      );

      expect(issued.displayNumber(draftLabel: 'Borrador'), '2026-42');
    });

    test('createdAt is available as the chronological fallback', () {
      final invoice = Invoice.fromJson({
        '_id': 'invoice-1',
        'groupId': 'group-1',
        'clientId': 'client-1',
        'status': 'draft',
        'createdAt': '2026-08-30T10:00:00.000Z',
      });

      expect(invoice.invoiceNumber, isEmpty);
      expect(invoice.registeredAt, DateTime.utc(2026, 8, 30, 10));
    });
  });
}
