import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'sub_menu_item.dart';

class GroupInvoicesBillingDetailsEdit extends StatelessWidget {
  final bool busy;
  final VoidCallback onEdit;

  const GroupInvoicesBillingDetailsEdit({
    super.key,
    required this.busy,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GroupInvoicesSubMenuItem(
      icon: Icons.edit_outlined,
      label: l.edit,
      selected: false,
      onPressed: busy ? null : onEdit,
    );
  }
}
