# Project structure

Hexora is a Flutter application. Its Node.js server is maintained separately;
`lib/services` contains the app's API clients and domain services, not server code.

## Source map

```text
lib/
├── main.dart                 # Flutter entry point
├── app/                      # Startup, provider wiring, session lifecycle
│   ├── bootstrap/
│   └── session/
├── models/                   # Data models, DTOs, serialization
├── services/                 # API clients, repositories, domain coordinators
│   ├── auth_user/
│   ├── config/
│   ├── groups/
│   ├── clients/
│   ├── time_tracking/
│   ├── service_catalog/
│   ├── invoicing/
│   ├── mail/
│   ├── tax/
│   └── telegram/             # Other service domains live alongside these
├── presentation/
│   ├── routes/               # Route definitions
│   ├── screens/
│   │   ├── home/
│   │   ├── workspace/        # Group dashboard and business modules
│   │   │   ├── dashboard_screen/
│   │   │   └── sections/     # invoices, expenses, mail, telegram, workers, …
│   │   ├── calendar/
│   │   ├── events/
│   │   ├── auth/
│   │   ├── notifications/
│   │   ├── agenda/
│   │   ├── profile/
│   │   └── settings/
│   ├── shared/               # Widgets reused across screens
│   ├── utils/                # Presentation helpers and reusable styling
│   ├── viewmodels/           # Presentation state and orchestration
│   └── enums/
├── state/                    # App-wide local state (currently locale)
├── navigation/               # Drawer and contextual navigation shell
├── theme/                    # Colors, typography, shapes, light/dark themes
└── l10n/                     # ARB translations and generated localization code

test/
├── models/
├── services/
├── presentation/
└── theme/

docs/
├── project_structure.md
├── architecture/             # Startup and architectural explanations
├── design/                   # Shared UI and platform design guidance
├── integrations/telegram/   # Telegram setup and reference guides
└── archive/                  # Historical notes, not executable app code
```

## Where to make a change

| Task | Start here |
| --- | --- |
| API URL or HTTP configuration | `lib/services/config/` |
| Group APIs and state | `lib/services/groups/` |
| Client APIs and contracts | `lib/services/clients/` |
| Worker time-tracking APIs | `lib/services/time_tracking/` |
| Service catalog API | `lib/services/service_catalog/` |
| Tax report requests | `lib/services/tax/tax_reporting_api.dart` |
| Tax tables, filters, client invoice lists | `lib/presentation/screens/workspace/sections/expenses/tax/` |
| Invoice screens | `lib/presentation/screens/workspace/sections/invoices/` |
| Invoice editor and form widgets | `lib/presentation/screens/workspace/sections/invoices/editor/` |
| Receipt editor | `lib/presentation/screens/workspace/sections/invoices/receipt_editor/` |
| Expense upload and import | `lib/presentation/screens/workspace/sections/expenses/upload/` |
| Expense supplier management | `lib/presentation/screens/workspace/sections/expenses/providers/` |
| Telegram screens | `lib/presentation/screens/workspace/sections/telegram/` |
| Mail screens | `lib/presentation/screens/workspace/sections/mail/` |
| Login and registration | `lib/presentation/screens/auth/` |
| App settings | `lib/presentation/screens/settings/` |
| Shared folder panels and sidebars | `lib/presentation/shared/widgets/` |
| Branding widgets | `lib/presentation/utils/logo/` |
| Branding image assets | `assets/images/branding/` |
| Locale preference | `lib/state/locale_provider.dart` |
| Color palettes and themes | `lib/theme/` |
| Theme selection and saved preference | `lib/theme/themes/app_theme.dart` and `lib/theme/theme_provider.dart` |
| App scaffold | `lib/navigation/main_scaffold.dart` |
| Horizontal navigation | `lib/navigation/horizontal_nav/` |
| Dependency registration | `lib/app/bootstrap/` and `lib/app/init_main.dart` |

## Navigation and theme folders

```text
lib/navigation/
├── main_scaffold.dart         # App shell
├── drawer/
│   ├── my_drawer.dart
│   └── legacy/                # Retained older drawer components
├── horizontal_nav/            # Navigation bar, models, and components
└── fab/                       # Floating actions, shell, and route actions

lib/theme/
├── theme_provider.dart        # Saved light/dark/system preference
├── themes/                    # AppTheme and light/dark/mobile definitions
├── colors/                    # Palettes and semantic color helpers
├── typography/                # Typography extension
├── components/                # Themed buttons, card and gradient surfaces
└── shapes/                    # Decorative headers, clippers, and cards
```

Use [the mobile design guide](design/mobile.md) for platform-specific UI rules.
Legacy drawer and palette implementations are retained; moving them does not
remove compatibility code or change which widgets the app uses.

## Shared UI and recurrence

Reusable controls live under `lib/presentation/shared/widgets/`:

- `app_bars/`: app-bar styling helpers.
- `buttons/`: button styles and reusable action buttons.
- `text_fields/`: static and editable text controls.
- `feedback/`: snackbars and message helpers.

These are source moves, not a consolidation of different implementations.
Keep feature-specific widgets with their feature: for example, the merged
calendar cell lives in `presentation/screens/calendar/widgets/` because it uses
calendar events.

Recurrence models and helpers live in `lib/models/group_model/recurrence/`,
with API access in `lib/services/groups/recurrence/`. The former mixed-case
recurrence directories are no longer used.

## Billing feature folders

Paths below are relative to `lib/presentation/screens/workspace/sections/`:

```text
invoices/
├── group_invoices_screen.dart  # Main module screen
├── group_invoices/            # List views, client widgets, mobile UI, sorting
├── flow/                      # Guided client/invoice flow and its controller
├── editor/                    # Invoice editor screens
│   ├── sections/
│   ├── view_sections/
│   └── widgets/
│       └── form/              # Form layout and content widgets
├── receipt_editor/            # Receipt editor and wizard
├── recurring_invoices/
├── recurring_receipts/
├── shared/
└── widgets/

expenses/
├── upload/                    # Expense upload screen and import UI
│   ├── form_sections/
│   ├── operations/
│   └── screen_sections/
├── providers/                 # Supplier forms and management views
└── tax/                       # Tax reporting tables and filters
```

The main invoice module and guided flow remain separate implementations; this
organization does not merge their controllers or change their entry points.
Expense widgets can still be embedded in the invoice module, but their source
now lives with the expenses feature.

## Test folders

`test/presentation/` groups UI tests by feature, including `invoices`,
`presupuestos`, `receipts`, `expenses`, `banking`, `clients`, `auth`, `calendar`,
`mail`, `telegram`, and `workspace`. Reusable component tests live in `shared`;
audit widget tests live in `audit`. Existing `maps`, `tax`, and
`recurring_invoices` suites keep their feature folders.

For example, run invoice UI tests with:

```sh
flutter test test/presentation/invoices
```

## Placement rules

- Keep a feature's widgets beside its screen until another feature needs them.
  Shared UI belongs in `presentation/shared`, not in a service directory.
- Keep API clients, repositories, and existing domain providers under the
  matching `services` domain. This layout change does not alter provider lifetimes
  or move business logic between layers.
- Use descriptive `snake_case` names for new Dart files and directories.
  Alphabetic prefixes are no longer needed to order the main layers or screens.
- Tests follow the same layer names; individual test files remain grouped by
  the behavior or feature they cover.
- Edit `lib/l10n/*.arb` and run `flutter gen-l10n` for translation changes.
  Keep generated model files beside their source models.
- Keep documentation under `docs`. Archived snapshots and notes are reference
  material, not current implementation instructions.

## Development and verification

Run commands from the directory containing `pubspec.yaml`:

```sh
flutter pub get
flutter analyze
flutter test
flutter test test/presentation/tax test/services/tax
flutter run -d chrome
```

After a source-directory migration, stop and restart an existing Flutter debug
session so the compiler and debugger pick up the new file paths.

The Flutter platform directories (`android`, `ios`, `web`, `windows`, `macos`,
`linux`), `assets`, `l10n`, and deployment entry scripts retain their locations.
Local build outputs, credentials, and ignored scratch files are not part of
the source reorganization.

## Previous paths

| Previous location | Current location |
| --- | --- |
| `lib/a-models/` | `lib/models/` |
| `lib/b-backend/` | `lib/services/` |
| `lib/c-frontend/` | `lib/presentation/` |
| `lib/c-frontend/ui-app/*-section/` | `lib/presentation/screens/<area>/` |
| `lib/c-frontend/ui-app/shared/` | `lib/presentation/shared/` |
| `lib/d-local-stateManagement/local/LocaleProvider.dart` | `lib/state/locale_provider.dart` |
| `lib/e-drawer-style-menu/` | `lib/navigation/` |
| `lib/f-themes/` | `lib/theme/` |
| `lib/app/bootstrapp/` | `lib/app/bootstrap/` |
| `test/a_models`, `test/b_backend`, `test/c_frontend`, `test/f_themes` | `test/models`, `test/services`, `test/presentation`, `test/theme` |

The billing cleanup also shortens the old `group_invoce_flow/screens/invoice_editor`
path to `invoices/editor`, moves `group_receipts_flow/screens/receipt_editor` to
`invoices/receipt_editor`, and removes the repeated `widgets/invoice_editor`
nesting. Expense-upload files formerly under `invoices/group_invoices` now live
under `expenses/upload`, with supplier management in `expenses/providers`.
These are source-location changes, not business-logic changes.
