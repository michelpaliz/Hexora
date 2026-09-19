# Large view boundaries

Expense imports, invoice lists, presupuesto editing, and mail composition are
split by responsibility. Their public entry points, state lifetimes, callbacks,
and API calls remain unchanged.

Paths below are relative to `lib/presentation/screens/workspace/sections/`.

| Area | Existing entry point | Extracted code |
| --- | --- | --- |
| Expense import | `expenses/upload/screen_sections/expense_upload_import_tabs_section.dart` | `expenses/upload/imports/` |
| Invoice list | `invoices/group_invoices/widgets/group_invoices_invoices_view.dart` | `invoices/group_invoices/invoice_list/` |
| Presupuesto editor | `presupuestos/templates/presupuesto_template_editor_screen.dart` | `presupuestos/templates/editor/` |
| Mail composition | `mail/compose/mail_compose_view.dart` | `mail/compose/sections/` and `mail/compose/widgets/` |

## Ownership

### Expense imports

`imports/sections/` contains the JSON tab, JSON steps, batch tab, and prediction
editing dialog. `imports/widgets/` contains workflow controls, progress/summary
cards, prediction review, file lists, onboarding, and document rows.
Data types live in `imports/models/`; preview formatting lives in `imports/utils/`.

The existing import-tabs mixin remains the interface to `ExpenseUploadScreen`.
The parent screen still owns controllers, import jobs, and lifecycle cleanup.

### Invoice lists

`invoice_list/controller/` contains the existing private list widget and its
`State`: API loading, date filters, sorting, summary data, and refresh behavior.
`sections/` contains list rendering and dialogs; `widgets/` contains totals,
month dividers, and payment notices. Sort/filter types live in `models/` and
client-label helpers in `utils/`.

Public types such as `InvoiceSortState` remain accessible through the original
view library, so callers do not need a new import.

### Presupuesto editor

`templates/editor/controller/` holds the existing private editor `State`,
including controller disposal, loading, saving, and document/template mutations.
This is not a new provider or independently owned controller instance.

`sections/` separates layout/step navigation, template selection, variables,
document preview, section/table editing, images, and common form controls.
Editor data types live in `models/`; autocomplete and markdown rendering live
in `widgets/`.

### Mail composition

`compose/sections/` contains recipient, subject, toolbar, message editor,
attachment, and invoice-option builders. These functions return the existing
widget expressions without adding a wrapper widget to the tree.

`compose/widgets/` also holds the template picker, recipient controls, recent
invoice dialog, and client picker. `MailComposeScreen` still owns recipients,
controllers, attachments, draft state, and sending.

## Dart library rules

The extracted files use `part` / `part of` to preserve existing private types and
interfaces. Import the owning screen/view library, not an individual part.
Register new parts in the owning library; keep imports on that library.

UI sections that access existing state use private extensions. Where necessary,
the owner delegates to a named extension explicitly. State mutations still go
through the owner's small `setState` forwarding method; do not create another
state owner or move controller creation/disposal into a rendering helper.

## Verification

Run from the app root:

```sh
flutter analyze
flutter test test/presentation/presupuestos test/presentation/mail test/presentation/expenses
flutter test test/presentation/invoices
flutter build web --debug --no-wasm-dry-run
```

The initial extraction was checked against the original declarations and widget
expressions, allowing formatting changes and the explicit state-update forwarding.
Behavioral changes should be tested separately from further source extraction.
