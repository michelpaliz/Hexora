import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/presentation/routes/group_invoices_route_args.dart';

void main() {
  final testGroup = Group(
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
        group: testGroup,
        initialMenu: 'invoices_issued',
        initialInvoiceId: 'invoice-1',
        initialReceiptId: 'receipt-1',
        initialBudgetId: 'budget-1',
      );

      expect(resolveGroupInvoicesRouteArgs(arguments), same(arguments));
    });

    test('wraps a group argument', () {
      final resolved = resolveGroupInvoicesRouteArgs(testGroup);

      expect(resolved?.group, same(testGroup));
      expect(resolved?.initialMenu, isNull);
    });

    test('supports the legacy map argument shape', () {
      final resolved = resolveGroupInvoicesRouteArgs({
        'group': testGroup,
        'initialMenu': 'receipts',
        'initialInvoiceId': 1,
        'initialReceiptId': 2,
        'initialBudgetId': 3,
      });

      expect(resolved?.group, same(testGroup));
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
