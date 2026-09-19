# Workspace dashboard

[group_dashboard.dart](group_dashboard.dart) is the entry point. It still creates
`GroupDashboardState` through the existing provider and chooses the wide/narrow
layout. This folder cleanup does not change state lifetimes, permissions,
section IDs, routes, or responsive breakpoints.

| Folder | Responsibility |
| --- | --- |
| `state/` | `GroupDashboardState` and `DashboardActions` |
| `navigation/` | Section identifiers, left navigation, and bottom bar |
| `layout/` | Wide/narrow workspace layout and content container |
| `overview/` | Admin and member overview bodies |
| `access/` | Role resolution and the role information screen |
| `header/` | Header views and their supporting widgets |
| `panels/` | Right-panel dispatcher, feature adapters, and panel widgets |
| `widgets/` | Small dashboard-only UI components |

The right-panel dispatcher is `panels/group_dashboard_right_panel.dart`; it is
not owned by the members feature. Individual panels are grouped by calendar,
members, invoices, notifications, workers, settings, and their other domains.
Shared panel cards live in `panels/widgets/`.

Business-module screens remain beside this shell under `../sections/`.
Do not move those modules into the dashboard just because the shell displays them.

The previous `dashboard_screen/dashboard/`, `screens/`, and `widgets/right_panel/`
paths have been replaced by these explicit responsibilities. Three empty,
unreferenced `ui/` placeholder files were removed; they remain in Git history.

From the app root:

```sh
flutter test test/presentation/workspace test/presentation/calendar test/presentation/mail
flutter analyze
flutter build web --debug --no-wasm-dry-run
```
