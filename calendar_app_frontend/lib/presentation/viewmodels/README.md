# Presentation viewmodels

Group viewmodels by the feature they coordinate. Do not repeat `presentation/`
or `view_model/` inside an already named `presentation/viewmodels/` folder.

| Folder | Responsibility |
| --- | --- |
| `groups/` | Group editor state, group viewmodels, and UI messaging |
| `groups/use_cases/` | Create/update groups, invite members, search users, upload photos |
| `invitations/` | Invitation list state and actions |
| `notifications/` | Notification actions and orchestration |
| `user/` | User profile state and actions |

`groups/group_editor_state.dart` is a file, not a directory.
`groups/group_view_model.dart` still owns both `GroupEditorViewModel` and
`GroupUndoneEventsViewModel`; this cleanup does not split classes or change their
provider lifetimes. `invitations/invitation_view_model.dart` contains
`InvitationViewModel`.

The canonical group update implementation is
`groups/use_cases/update_group_usecase.dart`. It checks the result of saving and
throws on failure. The unused nested implementation that performed an additional
refresh was removed; its source remains in Git history. Active behavior is unchanged.

API clients and domain services remain in `lib/services/`. State owned solely by
a screen, such as the dashboard, stays with that screen rather than moving here.
