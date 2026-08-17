# Hexora

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

---

## Project layout

The app follows a layered structure under `lib/`, with each layer prefixed
`a-`, `b-`, `c-`, … to keep the dependency direction obvious at a glance
(lower letters are lower-level).

### `lib/a-models/`
Plain Dart data models and DTOs — no Flutter, no backend calls.
`group_model/`, `invoice/`, `receipt/`, `notification_model/`, `user_model/`,
`mail/`, `jobs/`, `telegram/`, `downloads/`, `weather/`.

### `lib/b-backend/`
The API/service layer — one folder per domain, each talking to the backend
over `http`/`dio` and (where relevant) sockets:
`auth_user/`, `group_mng_flow/` (groups, events, recurrence, invites,
categories, agenda), `invoicing/`, `receipts/`, `vat/`, `expenses/`,
`statements/`, `enable_banking/`, `truelayer/`, `documents/` (private
documents), `mail/`, `emails/`, `notification/`, `telegram/`, `providers/`,
`insights/`, `blobUploader/`, `downloads/`, `user/`, `config/` (API
constants/client), `shared/`, `errorClases/`.

### `lib/c-frontend/ui-app/`
All screens and widgets, grouped by product area:

* **a-home-section/** — landing/home page
* **b-dashboard-section/** — the main group workspace: dashboard shell
  (`dashboard_screen/`) plus feature sections under `sections/`:
  `invoices/` (invoice + presupuesto editors, VAT summary, clients/receipts
  views), `workers/` (time tracking, monthly overview), `enable_banking/`
  (bank statements, invoice linking), `expenses/`, `mail/` (compose,
  inline invoice wizard), `telegram/`, `private_documents/` (vault,
  upload/detail dialogs), `services_clients/`, `members/`, `notifications/`,
  `business_hours/`, `group_settings/`, `undone_events/`,
  `upcoming_events/`, `graphs/`, `role_info/`
* **c-group-calendar-section/** — calendar screens and view adapters
* **d-event-section/** — create/edit event flows
* **e-log-user-section/** — login, register, password reset/forgot,
  email verification, splash, app download prompt
* **f-notification-section/** — notification center UI
* **g-agenda-section/** — agenda/list view of events
* **h-profile-section/** — user profile
* **i-settings-section/** — app settings
* **shared/** — cross-cutting widgets (app bar, side panels, popups)

### `lib/d-local-stateManagement/`
App-wide state (locale, and other local providers) — `local/`, `docs/`.

### `lib/e-drawer-style-menu/`
App shell navigation: contextual FAB and drawer.

### `lib/f-themes/`
Light/dark theming, color tokens, typography, shapes.

### `lib/l10n/`
Localization sources (`app_en.arb`, `app_es.arb`) and the generated
`app_localizations*.dart` files (via `flutter gen-l10n`, configured in
`l10n.yaml`). **Do not hand-edit the generated files** — edit the `.arb`
files and regenerate.

### `lib/app/`
App bootstrap/initialization (`bootstrapp/`, `init_main.dart`) and session
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
`lib/b-backend/config/`.

### Deployment

* `deploy_hexora_web.sh` / `deploy_hexora_web.ps1` — web deployment
* `deploy_mobile.sh` — mobile build/release helper

---

## Developer pointers

* **Entry point:** `lib/main.dart`
* **Routing:** `lib/c-frontend/routes/`
* **Dashboard shell & nav:** `lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/`
* **Calendar UI:** `lib/c-frontend/ui-app/c-group-calendar-section/`
* **Events:** `lib/c-frontend/ui-app/d-event-section/`
* **Invoicing:** `lib/c-frontend/ui-app/b-dashboard-section/sections/invoices/`
* **Worker time tracking:** `lib/c-frontend/ui-app/b-dashboard-section/sections/workers/`
* **API layer:** `lib/b-backend/`
* **State management:** `lib/d-local-stateManagement/`
* **Localization:** `lib/l10n/` (edit `.arb`, then `flutter gen-l10n`)
* **Theming:** `lib/f-themes/`
* **Tests:** `test/` (mirrors `lib/` layer names, e.g. `test/a_models/`, `test/b_backend/`, `test/c_frontend/`)
