# Calendar Flow Overview

This document explains how the calendar feature is wired together so new contributors can navigate the codebase quickly. The flow spans domains (data), coordinators (state + orchestration), and UI widgets.

## High-Level Architecture

```text
CalendarScreenCoordinator
  ├─ CalendarViewAdapter (UI bridge)
  │    ├─ CalendarState (ValueNotifiers)
  │    ├─ CalendarBinding/EventDomain (data source)
  │    └─ AppointmentBuilderBridge (event tiles)
  ├─ PresenceDomain / NotificationDomain hookups
  ├─ SocketManager (presence updates)
  └─ EventActionManager (edit/delete actions)
```

At runtime `MainCalendarView` instantiates a `CalendarScreenCoordinator`, which loads group/user data, wires sockets and passes a `CalendarViewAdapter` into the UI. The adapter exposes `buildCalendar`, `setViewMode`, weather toggles, etc.

## Key Files

| File | Responsibility |
| --- | --- |
| `lib/c-frontend/.../calendar/screen/main_calendar_view.dart` | Entry point widget (Scaffold with tabs, presence strip, calendar body). |
| `lib/c-frontend/.../calendar/presentation/coordinator/calendar_screen_coordinator.dart` | Orchestrates loading, sockets, and adapters. |
| `lib/c-frontend/.../calendar/presentation/view_adapater/adapter_flow/adapter/calendar_view_adapter.dart` | UI bridge that wraps `CalendarSurface` and `CalendarState`. |
| `lib/c-frontend/.../calendar/presentation/view_adapater/adapter_flow/adapter/calendar_state.dart` | Holds ValueNotifiers for events, view mode, weather, etc. |
| `lib/c-frontend/.../calendar/presentation/view_adapater/adapter_flow/view/calendar_surface.dart` | Builds the Syncfusion `SfCalendar`, hooking month cells, schedule headers, weather overlay. |
| `lib/c-frontend/.../calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_month_cell.dart` | Custom month cell visuals (day number, event dots, weather emoji). |
| `lib/c-frontend/.../calendar/screen/widgets/calendar_topbar.dart` | AppBar+TabBar with weather toggle button. |

## Data Flow

1. **Coordinator bootstraps**  
   - On `MainCalendarView` init, `_bootstrap` calls `_c.loadData`.  
   - The coordinator fetches the current group, user role, hooks sockets, and instantiates `CalendarViewAdapter`.
   - It triggers `EventDomain.manualRefresh()` so `CalendarState.dataSource` gets populated.

2. **Adapters & State**  
   - `CalendarViewAdapter` exposes `buildCalendar`, `setViewMode`, `setWeatherForecast`, `setShowWeatherIcons`.  
   - Internally it owns a `CalendarState` which contains ValueNotifiers for events, view mode, anchor date, `weatherForecast`, and `showWeatherIcons`.
   - `CalendarState.applyEvents` updates the Syncfusion `CalendarDataSource`.

3. **UI Rendering (CalendarSurface)**  
   - `CalendarSurface` listens to the ValueNotifiers via nested `ValueListenableBuilder`s.  
   - `monthCellBuilder` delegates to `buildMonthCell`, injecting the current forecast map (or an auto-generated demo map if nothing is set).  
   - Weather icons appear only when `showWeatherIcons` is true.

4. **Month Cell**  
   - `calendar_month_cell.dart` draws each day: selection ring, event count/dots, and optional weather badge (`emoji + grade`).  
   - `_shouldShowWeather` currently checks `summary.summary.isNotEmpty`.
   - Tooltips display the localized summary and comfort hints (hot/cold).

5. **Top Bar & Toggling**  
   - `CalendarTopBar` renders the title, tabs, and a weather toggle icon button.  
   - `MainCalendarView` keeps `_weatherIconsEnabled` state and calls `_c.calendarUI?.setShowWeatherIcons(value)` when toggled.

## Extending / Customizing

- **New data sources**: add them to `CalendarState` as ValueNotifiers and consume them in `CalendarSurface`.  
- **Weather API**: call `CalendarViewAdapter.setWeatherForecast(Map<DateTime, DaySummary>)` with live data (dates should be normalized Y/M/D).  
- **Additional view modes**: update `CalendarTabs`, `CalendarTabs.handleTabChanged`, and `CalendarState.setViewMode`.
- **Custom month visuals**: edit `calendar_month_cell.dart` – it is the single entry point for month cell rendering.

## How Weather Toggle Works

1. User taps the icon in `CalendarTopBar`.  
2. `MainCalendarView._toggleWeatherIcons` flips `_weatherIconsEnabled` and calls `CalendarViewAdapter.setShowWeatherIcons`.  
3. `CalendarState.showWeatherIcons` ValueNotifier updates, `CalendarSurface` rebuilds, and either passes the forecast map or an empty map to month cells.
4. Month cells show/hide the emoji accordingly without affecting the rest of the calendar.

## Entry Points for Debugging

- `MainCalendarView._bootstrap()` – check when/why data loading fails.
- `CalendarState.applyEvents()` – verify events are reaching the UI.
- `CalendarSurface.monthCellBuilder` – ensures month glyphs receive the right `events` and `weatherSummaries`.
- `CalendarScreenCoordinator.setViewMode()` – useful when debugging tab switching.

## File Location

Saved at `docs/calendar_flow_overview.md`. Add or expand sections as the feature evolves.
