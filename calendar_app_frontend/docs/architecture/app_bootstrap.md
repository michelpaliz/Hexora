# App boot & wiring — a human-friendly guide

This doc explains what happens in `main.dart`, why we register so many providers, and how everything fits together. Think of it as a map of the app’s **dependency graph** and **data flow**.

---

## TL;DR (what you should remember)

* We use **interfaces** (`I*`) for all network-facing things.
* **Repositories** own state/streams and hide tokens; **Domains** are UI-facing coordinators.
* `AuthService` wraps `AuthProvider` so UI listens to **one** place for auth state.
* `EventDomain` depends on the **event repository** and the **current group** from `GroupDomain`.

---

## Layers (mental model)

```
UI Widgets
   ⬇
Domains (UI logic/coordinators, ChangeNotifier)
   ⬇
Repositories (own streams/cache; inject tokens; call API clients)
   ⬇
API Clients (pure HTTP calls only)
   ⬇
Backend
```

* **API Clients**: Only HTTP. No token logic, no caching, no streams.
* **Repositories**: Wrap an API client and inject the token via a `tokenSupplier()`. They may keep caches and expose streams.
* **Domains**: UI helpers. They glue screens to repositories, do orchestration (e.g., refresh after a mutation), and hold lightweight UI state (`ValueNotifier`, etc).

---

## What `main.dart` actually wires

### 1) User stack

* `IUserApiClient` → `UserApiClient()`

  * Low-level HTTP for `/users`.
* `IUserRepository` → `UserRepository(apiClient, tokenSupplier)`

  * Pulls tokens from `AuthService.getToken()`.
  * Provides `getUserById`, `getUserBySelector`, avatar SAS refresh, etc.

**Why:** UI and other domains should never touch tokens or raw HTTP.

### 2) Auth stack

* `AuthApiClient` → HTTP calls for `/auth/*` (login/register/refresh).
* `AuthProvider(userRepository, authApi)` (ChangeNotifier)

  * Manages login/logout, token persistence (via `TokenStorage`), session restore.
  * After login, fetches the full `User` via `IUserRepository`.
* `AuthService(AuthProvider)`

  * Thin wrapper so the UI listens to one ChangeNotifier for auth state.
  * Exposes `getToken()` for other providers (repositories) to use.

**Why:** Keep auth concerns in one place while still using the user repository to fetch the actual user model.

### 3) Recurrence rules (events)

* `RecurrenceRuleApiClient`

  * HTTP client for recurrence-rule endpoints.
* `GroupEventResolver`

  * Optional helper to hydrate events with recurrence rules and expand recurrences for UI.

**Why:** Some screens need to expand recurrence strings into instances.

### 4) Events stack

* `IEventApiClient` → `EventApiClient(ruleService)`

* `IEventRepository` → `EventRepository(apiClient, tokenSupplier)`

  * Owns **per-group streams** and **in-memory cache**.
  * Exposes CRUD and `events$(groupId)`, `refreshGroup(groupId)`.

* `EventDomain(group, IEventRepository, GroupDomain)`

  * Listens to the repository, computes the visible window, triggers reminders.
  * No HTTP here.

**Why:** Repository handles reactive data and tokens; Domain coordinates with UI.

### 5) Groups stack

* `IGroupApiClient` → `HttpGroupApiClient()`
* `IGroupRepository` → `GroupRepository(apiClient, tokenSupplier)`

  * Owns group streams, role/invite metadata calls.
* `GroupDomain(groupRepository, userRepository, groupEventResolver, user)`

  * Manages current group selection and refresh flows for the signed-in user.

**Why:** Centralizes “which group is active” and re-fetch flows for UI.

### 6) Invitations, Notifications, Theme/Locale

* `InvitationRepository` & `InvitationDomain`
* `NotificationDomain`
* `ThemeManagement`, `ThemePreferenceProvider`, `LocaleProvider`
* `PresenceDomain`

**Why:** App-level UI state and utilities.

---

## The `ProxyProvider` bit (why it exists)

```dart
ProxyProvider2<GroupDomain, IEventRepository, EventDomain?>(
  update: (ctx, groupDomain, eventRepo, previous) {
    final current = groupDomain.currentGroup;
    if (current == null) return null;
    final edm = EventDomain(
      const [],
      context: ctx,
      group: current,
      repository: eventRepo,
      groupDomain: groupDomain,
    );
    // keep any existing callback
    edm.onExternalEventUpdate = previous?.onExternalEventUpdate
        ?? () => debugPrint('⚠️ Default fallback: no calendar UI registered.');
    return edm;
  },
)
```

* When the **current group changes**, we create a **new** `EventDomain` tied to that group.
* `EventDomain` then listens to `IEventRepository` and emits expanded events for the visible range.

---

## How widgets consume things (do this)

* **Always** depend on **interfaces**:

```dart
final userRepo = context.read<IUserRepository>();
final eventRepo = context.watch<IEventRepository>();
final eventDomain = context.watch<EventDomain?>(); // it can be null before a group is selected
final groupDomain = context.read<GroupDomain>();
final auth = context.watch<AuthService>();
```

* **Do not** read concrete classes unless they are the domain widgets you own.

---

## Common runtime oops & fixes

* **ProviderNotFoundException**:
  You requested `UserRepository` but registered `IUserRepository`. Either:

  * Change the read to `context.read<IUserRepository>()`, or
  * Register both types (interface + concrete) if you *really* need the concrete (prefer not to).

* **Hot-reload vs hot-restart**:
  After changing providers in `main.dart`, do a **hot-restart**.

* **Null EventDomain**:
  `EventDomain` is null until a `currentGroup` exists in `GroupDomain`. Check for null or guard UI.

---

## Adding a new feature quickly (recipe)

1. Create `IFeatureApiClient` + `FeatureApiClient` (HTTP only).
2. Create `IFeatureRepository` + `FeatureRepository(apiClient, tokenSupplier)` (streams, cache).
3. Create `FeatureDomain` if the UI needs orchestration/state glue.
4. Wire them in `main.dart`:

   * Provide the API client.
   * Provide the repository with `tokenSupplier: () => context.read<AuthService>().getToken()`.
   * Provide a domain (plain Provider/ChangeNotifierProvider or via ProxyProvider if it depends on other providers like `GroupDomain`).

---

## Mini cheatsheet (what to import)

* For repositories in widgets:
  `import '.../repository/i_user_repository.dart';`
* For domains in widgets:
  `import '.../domain/user_domain.dart';`
* For event expansion helpers in UI logic:
  `import '.../event/resolver/event_group_resolver.dart';` (if needed)

---

## Example: fetching a user in a widget

```dart
class ProfileName extends StatelessWidget {
  final String selector; // username or id

  const ProfileName({required this.selector, super.key});

  @override
  Widget build(BuildContext context) {
    final users = context.read<IUserRepository>();

    return FutureBuilder(
      future: users.getUserBySelector(selector),
      builder: (context, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        return Text(snap.data!.name.isNotEmpty ? snap.data!.name : snap.data!.userName);
      },
    );
  }
}
```

---

## Quick FAQ

* **Why inject tokens via `tokenSupplier` instead of reading TokenStorage from repositories?**
  It centralizes auth state in `AuthService`/`AuthProvider`, making repositories **testable** and **stateless** regarding auth.

* **Why domains and repositories instead of BLoC?**
  Same idea; we’ve just chosen a **simple ChangeNotifier + Notifiers** approach. You can swap to BLoC/Rx later; the interfaces keep it flexible.

* **Can I call API clients directly from widgets?**
  Prefer **repositories**. They handle tokens, caching, and keep your UI clean.

---

That’s it. If you keep the **interface → repository → domain** habit, your features stay plug-and-play and your widgets remain thin and testable.
