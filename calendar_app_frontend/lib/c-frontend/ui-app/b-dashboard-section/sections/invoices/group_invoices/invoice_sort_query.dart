import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_invoices_view.dart';

class InvoiceSortQueryParams {
  final String? sortBy;
  final String? sortDir;

  const InvoiceSortQueryParams({
    required this.sortBy,
    required this.sortDir,
  });
}

InvoiceSortQueryParams invoiceSortToQuery(InvoiceSortState state) {
  final sortDir = state.dir == InvoiceSortDir.asc ? 'asc' : 'desc';
  return switch (state.by) {
    InvoiceSortBy.number => InvoiceSortQueryParams(
        sortBy: 'number',
        sortDir: sortDir,
      ),
    // Keep backend-compatible date mode by omitting sortBy.
    InvoiceSortBy.date => InvoiceSortQueryParams(
        sortBy: null,
        sortDir: sortDir,
      ),
  };
}
