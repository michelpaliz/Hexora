part of '../../widgets/group_invoices_invoices_view.dart';

enum InvoiceSortBy { date, number }

enum InvoiceSortDir { asc, desc }

enum _InvoiceColumnSort {
  number,
  client,
  status,
  payment,
  date,
  taxableBase,
  vat,
  total,
}

class _InvoiceAmountRange {
  const _InvoiceAmountRange({this.min, this.max});
  final num? min;
  final num? max;

  bool get active => min != null || max != null;

  bool includes(num? value) {
    if (value == null) return false;
    if (min != null && value < min!) return false;
    if (max != null && value > max!) return false;
    return true;
  }
}

enum _InvoiceHeaderAction { toggleUnlinked, resolveLinks }

class InvoiceDateFilterState {
  const InvoiceDateFilterState({
    required this.fromDate,
    required this.toDate,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
}

class InvoiceSortState {
  final InvoiceSortBy by;
  final InvoiceSortDir dir;

  const InvoiceSortState({
    required this.by,
    required this.dir,
  });

  InvoiceSortState copyWith({
    InvoiceSortBy? by,
    InvoiceSortDir? dir,
  }) {
    return InvoiceSortState(
      by: by ?? this.by,
      dir: dir ?? this.dir,
    );
  }
}

InvoiceSortState nextInvoiceSortState(
  InvoiceSortState current,
  InvoiceSortBy selectedBy,
) {
  if (current.by == selectedBy) {
    return current.copyWith(
      dir: current.dir == InvoiceSortDir.desc
          ? InvoiceSortDir.asc
          : InvoiceSortDir.desc,
    );
  }
  return InvoiceSortState(by: selectedBy, dir: InvoiceSortDir.desc);
}
