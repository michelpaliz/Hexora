import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/sheet/linked_income_evidence.dart';

void main() {
  group('parseMoney', () {
    test('handles Spanish, English and numeric amounts', () {
      expect(LinkedIncomeEvidence.parseMoney('1.028,50 EUR'), 1028.50);
      expect(LinkedIncomeEvidence.parseMoney('485,87 €'), 485.87);
      expect(LinkedIncomeEvidence.parseMoney('1,028.50'), 1028.50);
      expect(LinkedIncomeEvidence.parseMoney('1.815'), 1815);
      expect(LinkedIncomeEvidence.parseMoney(247.57), 247.57);
      expect(LinkedIncomeEvidence.parseMoney('-'), isNull);
      expect(LinkedIncomeEvidence.parseMoney(null), isNull);
    });
  });

  test('exact amount, close date, payer missing from technical concept', () {
    final e = LinkedIncomeEvidence.fromRow(
      {
        'date': '2026-07-02',
        'concept': 'fatir188966339 b16841652000',
        'amountFormatted': '1.028,50 EUR',
        'linkedInvoicesTotalFormatted': '1.028,50 EUR',
      },
      [
        {
          'invoiceNumber': '194-26',
          'clientName': 'C.Prop Clevenvilla III',
          'issueDate': '2026-06-26',
          'amountFormatted': '1.028,50 EUR',
        }
      ],
    );
    expect(e.hasAmountDifference, isFalse);
    expect(e.dateGapDays, 6);
    expect(e.payerMissing, isTrue);
    expect(e.invoiceNumberInConcept, isFalse);
  });

  test('one-cent difference is flagged, not treated as exact', () {
    final e = LinkedIncomeEvidence.fromRow(
      {
        'date': '2026-06-26',
        'concept': 'transf. a su favor 00810692-cdad prop urb las estan',
        'amountFormatted': '485,87 EUR',
        'linkedInvoicesTotalFormatted': '485,88 EUR',
      },
      [
        {
          'invoiceNumber': '203-26',
          'clientName': 'Residencial Las Estancias',
          'issueDate': '2026-06-26',
        }
      ],
    );
    expect(e.hasAmountDifference, isTrue);
    expect(e.amountDifference, -0.01);
    // "las estan" is a truncated "Las Estancias".
    expect(e.payerInConcept, isTrue);
    final checks = e.checks(isEs: true, money: (v) => v.toStringAsFixed(2));
    expect(checks.first.state, EvidenceState.warning);
    expect(checks.first.label, contains('0.01'));
  });

  test('payer and invoice number found in concept', () {
    final e = LinkedIncomeEvidence.fromRow(
      {
        'date': '2026-07-10',
        'concept': 'TRANSFERENCIA MIRADORES FRA 199-26',
        'amount': 605,
      },
      [
        {
          'invoiceNumber': '199-26',
          'clientName': 'C.Prop Miradores',
          'issueDate': '2026-06-26',
          'amount': 605,
        }
      ],
    );
    expect(e.hasAmountDifference, isFalse);
    expect(e.payerInConcept, isTrue);
    expect(e.invoiceNumberInConcept, isTrue);
  });

  test('cleanConcept tidies spacing and all-caps text', () {
    expect(LinkedIncomeEvidence.cleanConcept('  traspaso  '), 'Traspaso');
    expect(LinkedIncomeEvidence.cleanConcept('fatir188966339 b16841652000'),
        'fatir188966339 b16841652000');
    expect(LinkedIncomeEvidence.cleanConcept('TRANSFERENCIA  RECIBIDA'),
        'Transferencia recibida');
  });
}
