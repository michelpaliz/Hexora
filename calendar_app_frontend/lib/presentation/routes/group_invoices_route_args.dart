import 'package:hexora/models/group/group.dart';

class GroupInvoicesRouteArgs {
  const GroupInvoicesRouteArgs({
    required this.group,
    this.initialMenu,
    this.initialInvoiceId,
    this.initialReceiptId,
    this.initialBudgetId,
  });

  final Group group;
  final String? initialMenu;
  final String? initialInvoiceId;
  final String? initialReceiptId;
  final String? initialBudgetId;
}

/// Resolves typed arguments and the legacy map shape used by invoice routes.
GroupInvoicesRouteArgs? resolveGroupInvoicesRouteArgs(Object? arguments) {
  if (arguments is GroupInvoicesRouteArgs) return arguments;
  if (arguments is Group) return GroupInvoicesRouteArgs(group: arguments);
  if (arguments is! Map) return null;

  final group = arguments['group'];
  if (group is! Group) return null;

  return GroupInvoicesRouteArgs(
    group: group,
    initialMenu: arguments['initialMenu']?.toString(),
    initialInvoiceId: arguments['initialInvoiceId']?.toString(),
    initialReceiptId: arguments['initialReceiptId']?.toString(),
    initialBudgetId: arguments['initialBudgetId']?.toString(),
  );
}
