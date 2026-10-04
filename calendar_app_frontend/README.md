# Hexora

> Backend handoff: [Backend fixes required](BACKEND_FIXES_REQUIRED.md) — confirmed blockers, investigation items, and acceptance checks.
> Additional findings: [App issues review](APP_ISSUES_REVIEW.md) — frontend issues and cross-app contract risks.

Hexora is the operating system I am building around the real needs of my
business. It brings scheduling, employees, clients, presupuestos, invoices,
receipts, expenses, banking, documents, email, and Telegram into one shared
workspace instead of spreading daily work across disconnected tools.

It is useful because it turns repetitive administration into a connected
workflow. Information entered once can continue through the full business
process: a client can receive a tailored presupuesto, the work can be planned
and assigned, employee hours can be recorded, the final invoice can be issued,
and the payment can be reconciled against the bank statement. The same team
and client information remains available throughout, reducing duplicate data
entry and avoidable mistakes.

## Why Hexora matters to the business

- **Less administrative work** — recurring schedules, reusable document
  templates, automatic calculations, and connected records reduce manual work.
- **Faster client service** — professional presupuestos, invoices, receipts,
  PDFs, and emails can be prepared and sent from the same workspace.
- **Better financial control** — expenses, VAT summaries, invoices, receipts,
  and bank movements are easier to review and reconcile.
- **Clearer team coordination** — shared calendars, worker time tracking,
  roles, and real-time updates help everyone work from current information.
- **More consistent operations** — client data, business documents, and
  communication history stay organized by group and are easier to find.
- **Capacity to grow** — the business can manage more clients and work without
  increasing administration at the same rate.

Hexora is not only a software project; it is becoming a practical business
tool shaped by the problems encountered in day-to-day operations.

Targets: Android, iOS, Web, Windows, macOS, and Linux from a single codebase.

## Install or update Hexora on an Android phone

Enable USB debugging, connect the phone with a data cable, and accept its
authorization prompt. From the project folder, run:

```bash
./scripts/install_android.sh
```

The script builds a release APK and installs it on the single connected phone
using `adb install -r`, preserving existing app data. It does not select an
emulator automatically. If several phones are connected, choose one with
`./scripts/install_android.sh --device SERIAL` (see `adb devices`).

Without a connected phone, the script saves `build/phone/Hexora-latest.apk`
for manual transfer. Use `./scripts/install_android.sh --build-only` to always
build without installing. Open the transferred APK on the phone to install it.

Updates require the same application ID and signing key. The current release
configuration uses the local development signing key; keep that key for future
updates. Installation failures never trigger an automatic uninstall.

Offline script checks: `python3 scripts/tests/test_install_android.py`.

---

## Project layout

The app uses descriptive layer names, with screens grouped by product area.
See the [project structure guide](docs/project_structure.md) for a source map,
feature locations, placement rules, and the previous-to-current path mapping.

### `lib/models/`

Data models, DTOs, and serialization.
`groups/`, `clients/`, `workers/`, `time_tracking/`, `calendar/`, `user/`,
`notifications/`, `documents/`, `service_catalog/`, `invoice/`, `presupuesto/`,
`receipt/`, `mail/`, `jobs/`, `telegram/`, `downloads/`, `weather/`.
See the [model ownership guide](lib/models/README.md).

### `lib/services/`

The API/service layer — one folder per domain, each talking to the backend
over `http`/`dio` and (where relevant) sockets:
`auth/`, `groups/` (groups, events, recurrence, invites,
categories, agenda), `clients/`, `time_tracking/`, `service_catalog/`,
`invoicing/`, `presupuestos/`, `receipts/`, `vat/`, `expenses/`,
`statements/`, `enable_banking/`, `truelayer/`, `documents/` (private
documents), `mail/`, `emails/`, `notification/`, `telegram/`, `providers/`,
`insights/`, `blob_storage/`, `downloads/`, `user/`, `config/` (API
constants/client), `shared/`, `errors/`.

### `lib/presentation/screens/`

All screens and widgets, grouped by product area:

* **home/** — landing/home page
* **workspace/** — the main group workspace: dashboard shell
  (`dashboard/`) plus feature sections under `sections/`:
  `invoices/` (invoice editor, VAT summary, client views), `presupuestos/`
  (documents, templates, invoice conversion), `receipts/` (receipt views,
  editor, recurring receipts), `workers/` (time tracking, monthly overview), `enable_banking/`
  (bank statements, invoice linking), `expenses/`, `mail/` (compose,
  inline invoice wizard), `telegram/`, `private_documents/` (vault,
  upload/detail dialogs), `services_clients/`, `members/`, `notifications/`,
  `business_hours/`, `group_settings/`, `undone_events/`,
  `upcoming_events/`, `graphs/`, `role_info/`
* **calendar/** — calendar screens and view adapters
* **events/** — create/edit event flows
* **auth/** — login, register, password reset/forgot,
  email verification, splash, app download prompt
* **notifications/** — notification center UI
* **agenda/** — agenda/list view of events
* **profile/** — user profile
* **settings/** — app settings

Cross-cutting widgets (app bars, side panels, popups) live in
`lib/presentation/shared/`, alongside `routes/`, `utils/`, and `viewmodels/`.

### `lib/state/`

App-wide local state, currently `locale_provider.dart`.

### `lib/navigation/`

App shell navigation: contextual FAB and drawer.

`main_scaffold.dart` holds the shell; `fab/`, `horizontal_nav/`, and `drawer/`
contain their respective navigation components.

### `lib/theme/`

Light/dark theming, color tokens, typography, shapes.

Definitions live in `themes/`, palettes in `colors/`, text styles in
`typography/`, and themed surfaces/buttons in `components/`.

### `lib/l10n/`

Localization sources (`app_en.arb`, `app_es.arb`) and the generated
`app_localizations*.dart` files (via `flutter gen-l10n`, configured in
`l10n.yaml`). **Do not hand-edit the generated files** — edit the `.arb`
files and regenerate.

### `lib/app/`

App bootstrap/initialization (`bootstrap/`, `init_main.dart`) and session
handling (`session/`, e.g. session-expiry redirects).

### `lib/main.dart`

Entry point: initializes services, sets up local notifications, and mounts
`HexoraApp` (theme, locale, routes, deep-link handling via
`onGenerateRoute`).

---

## Key capabilities

* **Groups & roles** — create/join groups, invite members, admin vs. member
  permissions gating dashboard sections.
* **Calendar & events** — monthly/weekly/daily/agenda views, recurring
  events, category/business-hours support.
* **Worker time tracking** — clock entries, monthly overview, Excel/Telegram
  import of hours.
* **Invoicing & presupuestos** — invoice editor with line-item blocks,
  drafts, evidence flow, email sending, PDF/JSON import/export, receipts,
  VAT summary by quarter.
* **Banking** — Enable Banking / TrueLayer statement import, linking bank
  movements to invoices, bulk downloads.
* **Private documents** — per-group document vault (upload, categorize,
  review status, expiry tracking).
* **Telegram integration** — chat view and document import from Telegram.
* **Notifications** — real-time via sockets, categorized and filterable.
* **Theming & i18n** — light/dark themes, English/Spanish.

---

## Getting started

```bash
flutter pub get
flutter gen-l10n        # regenerate lib/l10n/app_localizations*.dart if needed
flutter run              # pick a device/platform, or use -d chrome / -d windows / etc.
```

Run tests:

```bash
flutter test
```

API endpoints and other environment-specific values live in
`lib/services/config/`.

### Deployment

* `deploy_hexora_web.sh` / `deploy_hexora_web.ps1` — web deployment
* `deploy_mobile.sh` — mobile build/release helper

---

## Developer pointers

* **Entry point:** `lib/main.dart`
* **Routing:** `lib/presentation/routes/`
* **Dashboard shell & nav:** `lib/presentation/screens/workspace/dashboard/`
* **Calendar UI:** `lib/presentation/screens/calendar/`
* **Events:** `lib/presentation/screens/events/`
* **Invoicing:** `lib/presentation/screens/workspace/sections/invoices/`
* **Worker time tracking:** `lib/presentation/screens/workspace/sections/workers/`
* **API layer:** `lib/services/`
* **State management:** `lib/state/` (local preferences), domain providers under `lib/services/`
* **Localization:** `lib/l10n/` (edit `.arb`, then `flutter gen-l10n`)
* **Theming:** `lib/theme/`
* **Tests:** `test/` (mirrors `lib/` layer names, e.g. `test/models/`, `test/services/`, `test/presentation/`)
