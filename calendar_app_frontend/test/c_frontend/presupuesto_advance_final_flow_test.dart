import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_advance_final_flow.dart';

void main() {
  group('buildAdvanceInvoicePayload', () {
    test('builds payload with required/optional fields', () {
      final payload = buildAdvanceInvoicePayload(
        const AdvanceInvoiceConfigInput(
          percent: 70,
          projectBaseAmount: 1000,
          taxRate: 21,
          description: '  Anticipo 70% presupuesto  ',
        ),
      );
      expect(payload['advanceConfig']['percent'], 70);
      expect(payload['advanceConfig']['projectBaseAmount'], 1000);
      expect(payload['advanceConfig']['taxRate'], 21);
      expect(payload['advanceConfig']['description'], 'Anticipo 70% presupuesto');
    });

    test('throws for invalid percent', () {
      expect(
        () => buildAdvanceInvoicePayload(
          const AdvanceInvoiceConfigInput(percent: 0),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('buildFinalInvoicePayload', () {
    test('returns empty payload when advance invoice is not selected', () {
      expect(buildFinalInvoicePayload(), isEmpty);
      expect(buildFinalInvoicePayload(advanceInvoiceId: '   '), isEmpty);
    });

    test('includes trimmed advanceInvoiceId when selected', () {
      final payload = buildFinalInvoicePayload(advanceInvoiceId: '  adv-1  ');
      expect(payload['advanceInvoiceId'], 'adv-1');
    });
  });

  group('resolvePresupuestoInvoiceActionState', () {
    test('disables actions when status is not issued', () {
      final state = resolvePresupuestoInvoiceActionState(
        <String, dynamic>{'status': 'draft'},
      );
      expect(state.canCreateAdvance, isFalse);
      expect(state.canCreateFinal, isFalse);
    });

    test('disables advance when an advance invoice already exists', () {
      final state = resolvePresupuestoInvoiceActionState(
        <String, dynamic>{
          'status': 'issued',
          'advanceInvoices': [
            {'_id': 'i1', 'invoiceType': 'advance', 'status': 'issued'}
          ],
        },
      );
      expect(state.canCreateAdvance, isFalse);
      expect(state.canCreateFinal, isTrue);
    });

    test('disables final when final invoice already exists', () {
      final state = resolvePresupuestoInvoiceActionState(
        <String, dynamic>{
          'status': 'issued',
          'relatedInvoices': [
            {'_id': 'i2', 'invoiceType': 'final', 'status': 'issued'}
          ],
        },
      );
      expect(state.canCreateAdvance, isTrue);
      expect(state.canCreateFinal, isFalse);
    });
  });
}
