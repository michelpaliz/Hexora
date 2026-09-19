# Receipts

Receipt-specific UI and delivery helpers. The invoice workspace remains the
existing host; moving these files does not introduce a new route or menu.

## Entry points

- [views/group_receipts_view.dart](views/group_receipts_view.dart): receipt list embedded by the invoice workspace.
- [views/client_receipts_tab.dart](views/client_receipts_tab.dart): receipts for one client.
- [editor/receipt_editor_wizard_screen.dart](editor/receipt_editor_wizard_screen.dart): receipt creation/editing wizard.
- [recurring/recurring_receipts_screen.dart](recurring/recurring_receipts_screen.dart): recurring-receipt workflows.

## Ownership

- `editor/sections/` and `editor/widgets/`: wizard steps and form components.
- `widgets/`: receipt rows, details, and delivery dialog.
- `utils/`: receipt delivery status helpers.

State remains in the existing views and editor. Host-owned callbacks and refresh
behavior are unchanged.

APIs: `lib/services/receipts/receipts_api.dart` and
`lib/services/receipts/recurring_receipts_api.dart`.
Models: `lib/models/receipt/`.

Recurring receipts still reuse recurring-invoice components, and receipt PDF
actions still reuse invoice PDF helpers. These shared dependencies are preserved,
not copied or rewritten as part of the folder separation.

## Verification

From the app root:

```sh
flutter test test/presentation/receipts test/presentation/recurring_invoices test/presentation/invoices
```

The invoice mobile-layout suite has existing failures at 2.0 text scale; it is
included because invoices host these receipt views.

See [the project map](../../../../../../docs/project_structure.md) for the wider layout.
