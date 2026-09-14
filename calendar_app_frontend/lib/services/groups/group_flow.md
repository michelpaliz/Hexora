# What pieces do what?

| Piece                                     | What it is           | Main job                                                                                                                                                              | Talks to                           | Emits/Returns                                                                   |
| ----------------------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------- |
| `IGroupApiClient`                         | Interface            | Contract for group HTTP calls                                                                                                                                         | —                                  | —                                                                               |
| `HttpGroupApiClient`                      | HTTP client          | Calls backend `/groups/*` and `/calendars/*`                                                                                                                          | Server                             | `Group`, `MembersCount`, meta maps, `Calendar`                                  |
| `IGroupRepository`                        | Interface            | Contract for repo (incl. streams)                                                                                                                                     | —                                  | —                                                                               |
| `GroupRepository`                         | Data layer + streams | Keeps **per-user group cache** + **`userGroups$(userId)`** stream. CRUD updates cache & emits. Also handles photo upload commit.                                      | `IGroupApiClient`, `tokenSupplier` | `Stream<List<Group>>`, CRUD results                                             |
| `GroupDomain`                             | App state for groups | Subscribes to repo stream, exposes `watchGroupsForUser`, `refreshGroupsForCurrentUser`, mutations (create/update/delete/leave/respondInvite) and keeps `currentGroup` | `IGroupRepository`, `UserDomain`   | `notifyListeners()` on `currentGroup` changes; ValueNotifiers for roles/invites |
| `InvitationRepository / InvitationDomain` | Invites stack        | Invite actions if you keep them separate                                                                                                                              | Auth service / API                 | void / statuses                                                                 |
| `GroupCalendarLoader`                     | Navigation helper    | Resolves a `Group` from route args (object or id), sets `GroupDomain.currentGroup`, routes to calendar/no-calendar                                                    | `GroupDomain`, `UserDomain`, repo  | Widget routing                                                                  |
| `MainCalendarView`                        | Screen               | Uses `GroupDomain.currentGroup` to render the calendar UI for that group                                                                                              | `GroupDomain`, `EventDomain`       | UI                                                                              |

---

# Typical use-cases (step by step)

### 1) Show my groups (live)

1. UI gets `currentUser.id`.
2. UI → `GroupDomain.watchGroupsForUser(userId)` (stream).
3. Repo has a per-user cache; emits on initial refresh & later changes.
4. UI list updates automatically.

### 2) Create a group

1. UI → `GroupDomain.createGroup(group, userDomain)`.
2. Domain → `GroupRepository.createGroup()`.
3. On success Domain calls `refreshGroupsForCurrentUser(userDomain)` to **re-pull user → groupIds → repo.refreshUserGroupsByIds**.
4. Repo updates cache and **emits via `userGroups$`**. UI updates.

### 3) Update group (name/photo/…)

1. UI → `GroupDomain.updateGroup(updatedGroup, userDomain)`.
2. Repo PUT/PATCH; then Domain refreshes current user → repo refresh.
3. Stream emits; UI updates.

### 4) Delete / Leave group

1. UI → `GroupDomain.removeGroup(group, userDomain)` **or** `GroupRepository.leaveGroup(userId, groupId)`.
2. Domain refreshes current user → repo refresh.
3. Stream emits; group disappears from the list.

### 5) Respond to invite

1. UI → `GroupDomain.respondToInviteAndRefresh(groupId, userId, accepted, userDomain)`.
2. Repo PUT invite response.
3. Domain re-fetches user, then **repo.refreshUserGroupsByIds(...)**.
4. Stream emits; UI reflects joined/removed group.

### 6) Members counts / metadata

1. UI (e.g., dashboard) → `groupRepository.getMembersCount(groupId, mode: 'union'|'accepted')` or `getGroupMembersMeta(groupId)`.
2. One-shot calls; display results (Domain stores into ValueNotifiers if needed).

### 7) Upload group photo

1. UI → `GroupRepository.uploadAndCommitGroupPhoto(groupId, file)`.
2. Repo uploads blob, PATCHes backend; on success you can **refresh groups** so the new `photoUrl` shows.

### 8) Navigate to group calendar

1. UI calls route with `Group` or `groupId`.
2. `GroupCalendarLoader` resolves the `Group`, sets `GroupDomain.currentGroup`, and:

   * if `!group.hasCalendar` → `NoCalendarScreen`
   * else → `MainCalendarView(group: group)`

---

# Where logic should live?

| Concern                        | Best home                                 | Why                                             |
| ------------------------------ | ----------------------------------------- | ----------------------------------------------- |
| HTTP to `/groups`              | `HttpGroupApiClient`                      | Single-responsibility, testable                 |
| Token                          | `tokenSupplier` (DI)                      | Keeps API pure/testable                         |
| Per-user groups cache + stream | `GroupRepository`                         | One source of truth; many widgets can subscribe |
| Current group selection        | `GroupDomain.currentGroup`                | App/session state                               |
| Post-mutation re-sync          | `GroupDomain.refreshGroupsForCurrentUser` | Centralized after-effects                       |
| Members meta/count fetch       | `GroupRepository` (one-shots)             | Data access layer                               |
| Routing to calendar / fallback | `GroupCalendarLoader`                     | UI/navigation concern                           |

---

# Quick “recipes”

| Task                                  | Call this                                                                       | Notes                                   |              |
| ------------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------- | ------------ |
| Watch all my groups live              | `groupDomain.watchGroupsForUser(userId)`                                        | Subscribe once; rebuild UI on emissions |              |
| Force refresh after user/role changes | `groupDomain.refreshGroupsForCurrentUser(userDomain)`                           | Re-reads user → refreshes repo by IDs   |              |
| Create group                          | `groupDomain.createGroup(group, userDomain)`                                    | Auto refreshes streams                  |              |
| Update / Delete / Leave               | `groupDomain.updateGroup / removeGroup / groupRepository.leaveGroup`            | Always refresh after                    |              |
| Members count                         | `groupRepository.getMembersCount(groupId, mode: 'union'                         | 'accepted')`                            | Server-first |
| Members roles/invites                 | `groupRepository.getGroupMembersMeta(groupId)` → store in Domain ValueNotifiers | UI reads notifiers                      |              |
| Set current group                     | `groupDomain.currentGroup = group`                                              | Use post-frame if during build          |              |
| Open calendar                         | Push `AppRoutes.groupCalendar` with `Group` or `groupId`                        | Loader resolves & routes                |              |

---

# Data flow (short)

**UI** ⇄ **GroupDomain** ⇄ **GroupRepository (per-user stream + cache)** ⇄ **IGroupApiClient** ⇄ **Server**
User changes (invites/leave/create) → Domain re-fetches **User** → Repo refreshes **by groupIds** → **stream emits** → UI updates.
