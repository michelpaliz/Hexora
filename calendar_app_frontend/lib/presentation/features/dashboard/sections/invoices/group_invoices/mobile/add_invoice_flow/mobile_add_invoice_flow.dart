import 'package:flutter/material.dart';
import 'package:hexora/models/client/client.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoice_flow/screens/invoice_editor/invoice_editor_mobile_screen.dart';
import 'package:hexora/l10n/app_localizations.dart';

class MobileAddInvoiceFlow {
  const MobileAddInvoiceFlow._();

  static Future<bool> open({
    required BuildContext context,
    required Group group,
    required List<GroupClient> clients,
    String? initialClientId,
  }) async {
    if (clients.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noClientsYet)),
      );
      return false;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorMobileScreen(
          group: group,
          clients: clients,
          initialClientId: initialClientId,
        ),
      ),
    );
    return changed == true;
  }
}
