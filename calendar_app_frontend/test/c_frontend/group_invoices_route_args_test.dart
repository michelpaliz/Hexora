import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/routes/group_invoices_route_args.dart';

void main() {
  final group = Group(
    id: 'group-1',
    name: 'Test group',
    ownerId: 'owner-1',
    userRoles: const {},
    userIds: [],
    createdTime: DateTime(2026),
    description: '',
  );

  group('resolveGroupInvoicesRouteArgs', () {
    test('keeps typed route arguments', () {
      final arguments = GroupInvoicesRouteArgs(
        group: group,
        initialMenu: 'invoices_issued',
        initialInvoiceId: 'invoice-1',
        initialReceiptId: 'receipt-1',
        initialBudgetId: 'budget-1',
      );

      expect(resolveGroupInvoicesRouteArgs(arguments), same(arguments));
    });

    test('wraps a group argument', () {
      final resolved = resolveGroupInvoicesRouteArgs(group);

      expect(resolved?.group, same(group));
      expect(resolved?.initialMenu, isNull);
    });

    test('supports the legacy map argument shape', () {
      final resolved = resolveGroupInvoicesRouteArgs({
        'group': group,
        'initialMenu': 'receipts',
        'initialInvoiceId': 1,
        'initialReceiptId': 2,
        'initialBudgetId': 3,
      });

      expect(resolved?.group, same(group));
      expect(resolved?.initialMenu, 'receipts');
      expect(resolved?.initialInvoiceId, '1');
      expect(resolved?.initialReceiptId, '2');
      expect(resolved?.initialBudgetId, '3');
    });

    test('rejects missing or invalid groups', () {
      expect(resolveGroupInvoicesRouteArgs(null), isNull);
      expect(resolveGroupInvoicesRouteArgs({'group': 'group-1'}), isNull);
    });
  });
}
