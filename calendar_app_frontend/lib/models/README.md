# Data models

Use the domain that owns a model, even when the server scopes its data to a group.
API clients remain in `lib/services/`; screen state remains in presentation.

| Folder | Responsibility |
| --- | --- |
| `groups/` | Group configuration, roles, permissions, and invitations |
| `clients/` | Client identities, contracts, and invoice statistics |
| `workers/` | Worker identity and status |
| `time_tracking/` | Time entries, geofenced visits, history, and import payloads |
| `calendar/` | Calendars, agenda items, events, categories, and recurrence |
| `user/` | User identity, JSON mapping, parsing, and equality helpers |
| `notifications/` | Notifications, localization, update metadata, invitation status |
| `documents/` | Private documents and review metadata |
| `service_catalog/` | Service catalog records |
| `invoice/`, `presupuesto/`, `receipt/` | Billing document models |
| `mail/`, `telegram/` | Messaging models |
| `jobs/`, `downloads/`, `weather/` | Background jobs, downloads, and weather data |

Calendar event files live directly in `calendar/events/`, without another
`model/` layer. Recurrence helpers stay in `calendar/recurrence/utils/`.
The four user files share `user/`; there is no generic `json_folders/` layer.

Use snake_case filenames (`time_entry.dart`, `update_info.dart`,
`user_invitation_status.dart`). Moving a file does not change its public classes,
JSON fields, serialization behavior, or backend endpoints.

Some existing model helpers depend on Flutter or localization. This folder
cleanup preserves those dependencies; it does not redesign the model layer.
