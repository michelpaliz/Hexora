// Barrel file exporting all statements shared functionality
// This maintains backward compatibility while code is now organized in separate files

export 'shared/statements_shared_utils.dart';
export 'shared/statements_client_dialogs.dart';
export 'shared/statements_expense_upload_dialog.dart';
export 'shared/statements_invoice_suggest_dialog.dart';
export 'shared/invoice_link/invoice_link_dialog.dart';

import 'package:flutter/widgets.dart';

import 'shared/invoice_link/invoice_link_dialog.dart';
import 'shared/statements_client_dialogs.dart';
import 'shared/statements_expense_upload_dialog.dart';
import 'shared/statements_invoice_suggest_dialog.dart';
import 'shared/statements_shared_utils.dart';
import 'statements_controller.dart';

/// Main facade class maintaining backward compatibility with original API
class StatementsShared {
  /// Extract text from entry using a list of possible keys
  static String entryText(Map<String, dynamic> entry, List<String> keys) {
    return StatementsSharedUtils.entryText(entry, keys);
  }

  /// Get client label from entry
  static String clientLabel(
    dynamic l,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    return StatementsSharedUtils.clientLabel(l, s, entry);
  }

  /// Show AI-suggested clients dialog
  static Future<void> showSuggestionsDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    return StatementsClientDialogs.showSuggestionsDialog(context, s, entry);
  }

  /// Show full client picker dialog with search
  static Future<void> showClientPickerDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    return StatementsClientDialogs.showClientPickerDialog(context, s, entry);
  }

  /// Show AI-suggested invoices dialog
  static Future<void> showInvoiceSuggestionsDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    return StatementsInvoiceSuggestDialog.show(context, s, entry);
  }

  /// Show invoice/expense link wizard dialog
  static Future<void> showInvoiceLinkDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry, {
    required bool expenseOnly,
  }) {
    return InvoiceLinkDialog.show(context, s, entry, expenseOnly: expenseOnly);
  }

  /// Show expense upload dialog
  static Future<void> showExpenseUploadDialog(
    BuildContext context,
    StatementsController? s, {
    String? entryId,
  }) {
    return StatementsExpenseUploadDialog.show(context, s, entryId: entryId);
  }
}
