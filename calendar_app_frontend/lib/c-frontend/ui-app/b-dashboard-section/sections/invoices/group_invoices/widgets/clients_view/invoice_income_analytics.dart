import 'package:hexora/a-models/invoice/invoice.dart';

class InvoiceIncomeMonth {
  const InvoiceIncomeMonth({
    required this.month,
    this.billed = 0,
    this.collected = 0,
  });

  final DateTime month;
  final double billed;
  final double collected;

  InvoiceIncomeMonth copyWith({double? billed, double? collected}) {
    return InvoiceIncomeMonth(
      month: month,
      billed: billed ?? this.billed,
      collected: collected ?? this.collected,
    );
  }
}

class InvoiceIncomeAnalytics {
  const InvoiceIncomeAnalytics({
    required this.months,
    required this.billedTotal,
    required this.collectedTotal,
    required this.outstandingTotal,
    required this.invoiceCount,
  });

  final List<InvoiceIncomeMonth> months;
  final double billedTotal;
  final double collectedTotal;
  final double outstandingTotal;
  final int invoiceCount;

  double get monthlyAverage => months.isEmpty ? 0 : billedTotal / months.length;

  bool get hasActivity =>
      months.any((month) => month.billed != 0 || month.collected != 0);
}

InvoiceIncomeAnalytics buildInvoiceIncomeAnalytics({
  required List<Invoice> invoices,
  required int months,
  DateTime? now,
}) {
  final safeMonths = months < 1 ? 1 : months;
  final current = (now ?? DateTime.now()).toLocal();
  final firstMonth = DateTime(current.year, current.month - safeMonths + 1);
  final endExclusive = DateTime(current.year, current.month + 1);
  final values = <String, InvoiceIncomeMonth>{};

  for (var index = 0; index < safeMonths; index++) {
    final month = DateTime(firstMonth.year, firstMonth.month + index);
    values[_monthKey(month)] = InvoiceIncomeMonth(month: month);
  }

  var billedTotal = 0.0;
  var collectedTotal = 0.0;
  var outstandingTotal = 0.0;
  var invoiceCount = 0;

  for (final invoice in invoices) {
    final total = (invoice.total ?? 0).toDouble().clamp(0, double.infinity);
    final paid = _resolvedPaidAmount(invoice).clamp(0, total);
    final issuedAt = invoice.issuedAtResolved?.toLocal();

    if (issuedAt != null &&
        !issuedAt.isBefore(firstMonth) &&
        issuedAt.isBefore(endExclusive)) {
      final key = _monthKey(issuedAt);
      final point = values[key];
      if (point != null) {
        values[key] = point.copyWith(billed: point.billed + total);
      }
      billedTotal += total;
      outstandingTotal += (total - paid).clamp(0, double.infinity);
      invoiceCount++;
    }

    final paidAt = invoice.paidAt?.toLocal();
    if (paid > 0 &&
        paidAt != null &&
        !paidAt.isBefore(firstMonth) &&
        paidAt.isBefore(endExclusive)) {
      final key = _monthKey(paidAt);
      final point = values[key];
      if (point != null) {
        values[key] = point.copyWith(collected: point.collected + paid);
      }
      collectedTotal += paid;
    }
  }

  return InvoiceIncomeAnalytics(
    months: values.values.toList(growable: false),
    billedTotal: billedTotal,
    collectedTotal: collectedTotal,
    outstandingTotal: outstandingTotal,
    invoiceCount: invoiceCount,
  );
}

double _resolvedPaidAmount(Invoice invoice) {
  final explicit = invoice.paidAmount?.toDouble();
  if (explicit != null) return explicit;
  final status = (invoice.paymentStatus ?? '').trim().toLowerCase();
  return status == 'paid' || status == 'pagada' || status == 'pagado'
      ? (invoice.total ?? 0).toDouble()
      : 0;
}

String _monthKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
