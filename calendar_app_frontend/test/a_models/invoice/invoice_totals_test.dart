import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/invoice.dart';

void main() {
  group('Invoice totals', () {
    test('uses refreshed totals object before top-level aliases', () {
      final invoice = Invoice.fromJson({
        'id': 'inv-228-26',
        'invoiceNumber': '228-26',
        'groupId': 'group-1',
        'clientId': 'client-1',
        'subtotal': 3064.05,
        'taxTotal': 643.46,
        'total': 3707.51,
        'totalFormatted': '3.707,51 EUR',
        'totals': {
          'subtotal': 3414.05,
          'taxTotal': 716.95,
          'total': 4131.00,
          'totalFormatted': '4.131,00 EUR',
        },
        'lines': [
          {
            'invoiceId': 'inv-228-26',
            'position': 1,
            'description': 'Line payload is not the row total source',
            'quantity': 1,
            'unitPrice': 999,
            'taxRate': 21,
          },
        ],
      });

      expect(invoice.subtotal, 3414.05);
      expect(invoice.taxTotal, 716.95);
      expect(invoice.total, 4131.00);
      expect(invoice.totalFormatted, '4.131,00 EUR');
    });

    test('falls back to top-level aliases when totals object is absent', () {
      final invoice = Invoice.fromJson({
        'id': 'draft-1',
        'invoiceNumber': 'D-1',
        'groupId': 'group-1',
        'clientId': 'client-1',
        'subtotal': 180,
        'taxTotal': 37.8,
        'total': 217.8,
        'totalFormatted': '217,80 EUR',
      });

      expect(invoice.subtotal, 180);
      expect(invoice.taxTotal, 37.8);
      expect(invoice.total, 217.8);
      expect(invoice.totalFormatted, '217,80 EUR');
    });
  });
}
