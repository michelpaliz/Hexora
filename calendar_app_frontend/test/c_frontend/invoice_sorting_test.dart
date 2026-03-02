import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/invoice_sort_query.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_invoices_view.dart';

void main() {
  group('invoice sort query mapping', () {
    test('number+desc maps to sortBy=number&sortDir=desc', () {
      final qp = invoiceSortToQuery(
        const InvoiceSortState(
          by: InvoiceSortBy.number,
          dir: InvoiceSortDir.desc,
        ),
      );
      expect(qp.sortBy, 'number');
      expect(qp.sortDir, 'desc');
    });

    test('number+asc maps to sortBy=number&sortDir=asc', () {
      final qp = invoiceSortToQuery(
        const InvoiceSortState(
          by: InvoiceSortBy.number,
          dir: InvoiceSortDir.asc,
        ),
      );
      expect(qp.sortBy, 'number');
      expect(qp.sortDir, 'asc');
    });

    test('date sort does not send number sortBy', () {
      final qp = invoiceSortToQuery(
        const InvoiceSortState(
          by: InvoiceSortBy.date,
          dir: InvoiceSortDir.desc,
        ),
      );
      expect(qp.sortBy, isNull);
      expect(qp.sortDir, 'desc');
    });
  });

  group('nextInvoiceSortState', () {
    test('selecting same column toggles dir', () {
      const current = InvoiceSortState(
        by: InvoiceSortBy.number,
        dir: InvoiceSortDir.desc,
      );
      final next = nextInvoiceSortState(current, InvoiceSortBy.number);
      expect(next.by, InvoiceSortBy.number);
      expect(next.dir, InvoiceSortDir.asc);
    });

    test('selecting different column switches to desc by default', () {
      const current = InvoiceSortState(
        by: InvoiceSortBy.number,
        dir: InvoiceSortDir.asc,
      );
      final next = nextInvoiceSortState(current, InvoiceSortBy.date);
      expect(next.by, InvoiceSortBy.date);
      expect(next.dir, InvoiceSortDir.desc);
    });
  });
}
