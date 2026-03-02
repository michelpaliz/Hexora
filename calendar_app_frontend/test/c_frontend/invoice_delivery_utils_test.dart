import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/invoice_delivery_utils.dart';

void main() {
  group('invoice delivery mapping', () {
    test('not_sent maps to No enviada', () {
      final data = invoiceDeliveryViewData('not_sent');
      expect(data.status, 'not_sent');
      expect(data.labelEs, 'No enviada');
    });

    test('sent maps to Enviada', () {
      final data = invoiceDeliveryViewData('sent');
      expect(data.status, 'sent');
      expect(data.labelEs, 'Enviada');
    });

    test('failed maps to Fallo envio', () {
      final data = invoiceDeliveryViewData('failed');
      expect(data.status, 'failed');
      expect(data.labelEs, 'Fallo envio');
    });
  });
}
