import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/invoice_income_analytics.dart';

void main() {
  test('aggregates billed and collected values by their respective months', () {
    final analytics = buildInvoiceIncomeAnalytics(
      now: DateTime(2026, 8, 15),
      months: 3,
      invoices: [
        _invoice(
          id: 'june-partial',
          total: 100,
          issuedAt: DateTime(2026, 6, 5),
          paidAmount: 60,
          paidAt: DateTime(2026, 7, 2),
        ),
        _invoice(
          id: 'august-paid',
          total: 200,
          issuedAt: DateTime(2026, 8, 1),
          paymentStatus: 'paid',
          paidAt: DateTime(2026, 8, 10),
        ),
        _invoice(
          id: 'outside-range',
          total: 500,
          issuedAt: DateTime(2026, 5, 31),
          paidAmount: 500,
          paidAt: DateTime(2026, 5, 31),
        ),
      ],
    );

    expect(analytics.months, hasLength(3));
    expect(analytics.months[0].billed, 100);
    expect(analytics.months[1].collected, 60);
    expect(analytics.months[2].billed, 200);
    expect(analytics.months[2].collected, 200);
    expect(analytics.billedTotal, 300);
    expect(analytics.collectedTotal, 260);
    expect(analytics.outstandingTotal, 40);
    expect(analytics.invoiceCount, 2);
    expect(analytics.monthlyAverage, 100);
    expect(analytics.hasActivity, isTrue);
    expect(analytics.clientTotals, {'client': 300});
    expect(analytics.averagePaymentDays, 9);
    expect(analytics.collectionRatio, closeTo(260 / 300, .00001));
  });

  test('returns a stable empty range when no invoices match', () {
    final analytics = buildInvoiceIncomeAnalytics(
      now: DateTime(2026, 8, 15),
      months: 6,
      invoices: const [],
    );

    expect(analytics.months, hasLength(6));
    expect(analytics.billedTotal, 0);
    expect(analytics.collectedTotal, 0);
    expect(analytics.outstandingTotal, 0);
    expect(analytics.monthlyAverage, 0);
    expect(analytics.hasActivity, isFalse);
    expect(analytics.averagePaymentDays, isNull);
    expect(analytics.collectionRatio, isNull);
  });

  test('older invoice collections do not inflate the issued cohort ratio', () {
    final analytics = buildInvoiceIncomeAnalytics(
      now: DateTime(2026, 8),
      months: 1,
      invoices: [
        _invoice(
            id: 'old',
            total: 500,
            issuedAt: DateTime(2026, 7),
            paidAmount: 500,
            paidAt: DateTime(2026, 8, 2)),
        _invoice(
            id: 'new',
            total: 100,
            issuedAt: DateTime(2026, 8, 1),
            paidAmount: 20,
            paidAt: DateTime(2026, 8, 3)),
        Invoice(
            id: 'draft',
            invoiceNumber: '',
            groupId: 'group',
            clientId: 'client',
            status: 'draft',
            total: 900,
            issuedAt: DateTime(2026, 8, 1)),
      ],
    );
    expect(analytics.billedTotal, 100);
    expect(analytics.collectedTotal, 520);
    expect(analytics.outstandingTotal, 80);
    expect(analytics.collectionRatio, .2);
    expect(analytics.averagePaymentDays, isNull);
    expect(analytics.invoiceCount, 1);
  });
}

Invoice _invoice({
  required String id,
  required num total,
  required DateTime issuedAt,
  num? paidAmount,
  DateTime? paidAt,
  String? paymentStatus,
}) {
  return Invoice(
    id: id,
    invoiceNumber: id,
    groupId: 'group',
    clientId: 'client',
    total: total,
    issuedAt: issuedAt,
    paidAmount: paidAmount,
    paidAt: paidAt,
    paymentStatus: paymentStatus,
  );
}
