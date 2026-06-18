import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';

void main() {
  group('PresupuestosApi advance/final invoice URIs', () {
    final api = PresupuestosApi();

    test('buildCreateAdvanceInvoiceUri uses new endpoint', () {
      final uri = api.buildCreateAdvanceInvoiceUri('p1');
      expect(uri.path, '/api/presupuestos/p1/create-advance-invoice');
    });

    test('buildCreateFinalInvoiceUri uses new endpoint', () {
      final uri = api.buildCreateFinalInvoiceUri('p1');
      expect(uri.path, '/api/presupuestos/p1/create-final-invoice');
    });
  });
}
