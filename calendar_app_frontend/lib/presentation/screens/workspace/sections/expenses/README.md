# Expenses

`gastos_module_screen.dart` is the existing expenses module entry point.
Folder changes do not alter routes, API calls, or controller lifetimes.

- `audit/`: expense VAT audit and suspect-expense review views.
- `ocr/`: OCR reprocessing results screen used by the existing route and review flow.
- `upload/`: expense uploads, JSON/batch imports, and their state/UI sections.
- `providers/`: supplier forms and management views.
- `tax/`: tax reporting tables and filters.

APIs remain in `lib/services/expenses/` and `lib/services/suspects/`.
Shared OCR job tracking remains in `lib/presentation/shared/jobs/`.

Audit badges, date fields, info chips, and labels live in
`lib/presentation/shared/widgets/audit/`. Audit formatting/label helpers live in
`lib/presentation/shared/utils/audit/`; generic money formatting lives in
`lib/presentation/shared/utils/formatting/`. Invoice-specific audits remain with
the invoices feature and reuse the same shared components.

Run the focused checks from the app root:

```sh
flutter test test/presentation/audit test/presentation/expenses test/presentation/shared/money_format_utils_test.dart
```
