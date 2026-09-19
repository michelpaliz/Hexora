# What pieces do what?

| Piece                     | What it is                | Main job                                                                                                                     | Talks to                          | Emits/Returns                                                                     |
| ------------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------- |
| `IEventApiClient`         | Interface                 | Contract for API calls                                                                                                       | —                                 | —                                                                                 |
| `EventApiClient`          | HTTP client               | Calls backend (`/events/*`) and RRULE service when needed                                                                    | Server, `RecurrenceRuleApiClient` | `Event`, `List<Event>`                                                            |
| `IEventRepository`        | Interface                 | Contract for repo                                                                                                            | —                                 | —                                                                                 |
| `EventRepository`         | Data layer + streams      | Keeps **per-group cache** + **`events$(groupId)`** stream. CRUD syncs cache + emits.                                         | `IEventApiClient`, tokenSupplier  | `Stream<List<Event>>`, CRUD results                                               |
| `EventDomain`             | Coordinator for one group | Subscribes to repo stream; exposes `watchEvents()`, `manualRefresh()`, and CRUD helpers; triggers reminders; minimal UI glue | `IEventRepository`, `GroupDomain` | `Stream<List<Event>>` (via repo), `ValueNotifier<List<Event>>` (expanded UI list) |
| `GroupEventResolver`      | (Optional helper)         | Hydrates rules + expands recurrences (your helper lives here now)                                                            | `RecurrenceRuleApiClient`         | `List<Event>` hydrated/expanded                                                   |
| `RecurrenceRuleApiClient` | HTTP client               | Creates/reads recurrence rules                                                                                               | Server                            | Rule objects / strings                                                            |
| `SocketManager`           | Realtime                  | Listens to `created/updated/deleted` events and forwards to repo methods                                                     | Repo                              | Live updates into repo caches                                                     |
| `CalendarUIController`    | UI controller             | Listens to `EventDomain.watchEvents()`, computes day view, nudges calendar to redraw                                         | `EventDomain`, `GroupDomain`      | Updated `EventDataSource`, UI refresh                                             |
| `EventDataSource`         | UI adapter                | Bridges events → Syncfusion calendar                                                                                         | UI                                | Appointments to render                                                            |

---

# Typical use-cases (what happens, step by step)

### 1) Create an event

1. UI → `EventDomain.createEvent(context, event)`
2. Domain → `EventRepository.createEvent(event)`
3. Repo → API client POST; on success: add to cache, **emit** via `events$(groupId)`
4. Domain syncs notifications; UI redraws automatically.

### 2) Update an event

1. UI → `EventDomain.updateEvent(context, event)`
2. Repo PUTs; replaces item in cache; **emit**
3. Domain re-syncs notifications; UI refresh.

### 3) Delete an event

1. UI → `EventDomain.deleteEvent(id)`
2. Repo DELETEs; removes from all group caches where it matches `id` or `rawRuleId`; **emit**
3. Domain best-effort cancel reminders; UI refresh.

### 4) Mark event done / undone

1. UI → `EventDomain.updateEvent` or a dedicated `markEventAsDone`
2. Repo PUTs; updates cache; **emit**
3. UI refresh.

### 5) Fetch events for a group (initial load / pull-to-refresh)

1. UI/Domain → `EventDomain.manualRefresh(context)`
2. Domain → `EventRepository.refreshGroup(groupId)`
3. Repo GETs all, hydrates cache, **emit**
4. Calendar listens and updates.

### 6) Live updates (sockets)

1. Socket receives `created/updated/deleted`
2. `EventRepository.onSocketCreated/Updated/Deleted(groupId, json)`
3. Repo mutates cache + **emit**
4. Calendar updates automatically.

### 7) Recurring events shown in calendar

* You already generate occurrences (via your RRULE expander).
* Keep expansion in **Domain/UI helper** path (or in `GroupEventResolver.expandForRange`) to avoid polluting the repo cache with thousands of instances.
* Flow: Repo provides **base events** → Domain/UI **expands for the visible window** → Calendar renders.

---

# Where to put what logic?

| Concern                 | Best home                               | Why                                         |
| ----------------------- | --------------------------------------- | ------------------------------------------- |
| HTTP calls              | `EventApiClient`                        | Single responsibility; testable             |
| Auth token              | `tokenSupplier` (in DI)                 | Keeps API pure and testable                 |
| Caching + Streams       | `EventRepository`                       | One source of truth; easy to share          |
| Recurrence expansion    | `GroupEventResolver` (or a pure helper) | Derived UI data; don’t bloat the repo cache |
| UI selection/day filter | `CalendarUIController`                  | View concern                                |
| Notifications           | `EventDomain`                           | Side-effect near business logic             |

---

# Quick “recipes”

| Task                               | Call this                                                          | Notes                                  |
| ---------------------------------- | ------------------------------------------------------------------ | -------------------------------------- |
| Watch all events for current group | `eventDomain.watchEvents()`                                        | Subscribe once in your controller      |
| Force refresh from backend         | `eventDomain.manualRefresh(context)`                               | Repo pulls fresh, emits stream         |
| Create/update/delete               | `eventDomain.createEvent / updateEvent / deleteEvent`              | Repo updates cache + emits             |
| Expand recurrences for month       | Use your expander on the snapshot from the stream                  | Don’t store expanded instances in repo |
| React to sockets                   | Call `repo.onSocketCreated/Updated/Deleted` from your socket layer | Keeps cache live                       |

---

# Data flow (short)

**UI** ⇄ **EventDomain** ⇄ **EventRepository (streams + cache)** ⇄ **IEventApiClient** ⇄ **Server**
…and **SocketManager** feeds back **→ EventRepository** (keeps streams hot).
