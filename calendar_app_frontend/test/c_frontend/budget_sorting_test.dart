import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/budget_sort_query.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_budgets_view.dart';

void main() {
  group('budget sort query mapping', () {
    test('number+desc maps to sortBy=number&sortDir=desc', () {
      final qp = budgetSortToQuery(
        const BudgetSortState(
          by: BudgetSortBy.number,
          dir: BudgetSortDir.desc,
        ),
      );
      expect(qp.sortBy, 'number');
      expect(qp.sortDir, 'desc');
    });

    test('number+asc maps to sortBy=number&sortDir=asc', () {
      final qp = budgetSortToQuery(
        const BudgetSortState(
          by: BudgetSortBy.number,
          dir: BudgetSortDir.asc,
        ),
      );
      expect(qp.sortBy, 'number');
      expect(qp.sortDir, 'asc');
    });

    test('date sort does not send number sortBy', () {
      final qp = budgetSortToQuery(
        const BudgetSortState(
          by: BudgetSortBy.date,
          dir: BudgetSortDir.desc,
        ),
      );
      expect(qp.sortBy, isNull);
      expect(qp.sortDir, 'desc');
    });
  });

  group('nextBudgetSortState', () {
    test('selecting same column toggles dir', () {
      const current = BudgetSortState(
        by: BudgetSortBy.number,
        dir: BudgetSortDir.desc,
      );
      final next = nextBudgetSortState(current, BudgetSortBy.number);
      expect(next.by, BudgetSortBy.number);
      expect(next.dir, BudgetSortDir.asc);
    });

    test('selecting different column switches to desc by default', () {
      const current = BudgetSortState(
        by: BudgetSortBy.number,
        dir: BudgetSortDir.asc,
      );
      final next = nextBudgetSortState(current, BudgetSortBy.date);
      expect(next.by, BudgetSortBy.date);
      expect(next.dir, BudgetSortDir.desc);
    });
  });
}
