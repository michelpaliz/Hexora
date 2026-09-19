# Presupuestos

Source ownership for presupuesto documents, templates, and invoice conversion.
This folder split does not change navigation, API endpoints, or state lifetimes.

## Entry points

- [presupuestos_module_screen.dart](presupuestos_module_screen.dart): dashboard module, menu selection, and client loading.
- [views/presupuestos_view.dart](views/presupuestos_view.dart): existing list/create workflow, also embedded by the invoice workspace. The public `GroupInvoicesBudgetsView` name is preserved for compatibility.
- [templates/presupuesto_template_editor_screen.dart](templates/presupuesto_template_editor_screen.dart): template and document editing.

## Ownership

- `views/sections/`: Dart `part` files for the list/create workflow; keep them with their parent library.
- `documents/`: draft/workspace helpers and document actions.
- `templates/`: template editor, variables, and image library.
- `conversion/`: advance/final invoice conversion and its supporting views/helpers.
- `utils/`: presupuesto sorting queries.
- `widgets/`: feature-specific preview UI.

State remains in the existing screen/view `State` classes and document/conversion
helpers; no new provider or independently owned controller was introduced.
The template editor's private state now lives in `templates/editor/controller/`,
with rendering in `templates/editor/sections/`, data types in `models/`, and
autocomplete/markdown widgets in `widgets/`. These are parts of the original
screen library; keep importing the screen rather than a part file.

API: `lib/services/presupuestos/presupuestos_api.dart`.
Model: `lib/models/presupuesto/presupuesto_kind.dart`.

Invoice PDF/block editors, side-menu controls, and shared document widgets remain
shared dependencies. Keep cross-feature imports explicit; do not duplicate these
implementations merely to make the folder self-contained.

## Verification

From the app root:

```sh
flutter test test/presentation/presupuestos test/services/presupuestos test/models/presupuesto
flutter test test/presentation/telegram/telegram_presupuesto_picker_dialog_test.dart test/services/telegram/telegram_presupuesto_send_test.dart
```

See [the project map](../../../../../../docs/project_structure.md) for the wider layout.
