import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/invoice_income_analytics.dart';

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
