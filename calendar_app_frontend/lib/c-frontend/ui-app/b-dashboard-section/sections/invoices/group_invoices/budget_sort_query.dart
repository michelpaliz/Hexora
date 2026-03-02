import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_budgets_view.dart';

class BudgetSortQueryParams {
  final String? sortBy;
  final String? sortDir;

  const BudgetSortQueryParams({
    required this.sortBy,
    required this.sortDir,
  });
}

BudgetSortQueryParams budgetSortToQuery(BudgetSortState state) {
  final sortDir = state.dir == BudgetSortDir.asc ? 'asc' : 'desc';
  return switch (state.by) {
    BudgetSortBy.number => BudgetSortQueryParams(
        sortBy: 'number',
        sortDir: sortDir,
      ),
    // Keep backend-compatible date mode by omitting sortBy.
    BudgetSortBy.date => BudgetSortQueryParams(
        sortBy: null,
        sortDir: sortDir,
      ),
  };
}
