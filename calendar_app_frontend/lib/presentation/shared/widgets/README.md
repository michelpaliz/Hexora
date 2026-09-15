# Shared widgets

Use these folders for presentation components reused across screens. Keep
feature-specific widgets with their feature and API clients in `lib/services/`.

| Folder | Responsibility |
| --- | --- |
| `app_bars/` | Shared app-bar styles |
| `audit/` | Audit badges, date fields, info chips, and labels |
| `avatars/` | User avatars, status rows, group thumbnails, and avatar helpers |
| `buttons/` | Reusable action buttons and styles |
| `dialogs/` | Loading and premium-upgrade dialogs |
| `documents/` | Document cards, detail pages, and inline PDF previews |
| `feedback/` | Snackbars and feedback helpers |
| `text_fields/` | Reusable text controls and styles |
| `weather/` | Weather greeting cards and forecast lists |

Import `documents/pdf_inline_preview.dart`, not its platform-specific files.
Its conditional export selects the existing web implementation or non-web stub.

Weather widgets use `lib/services/weather/` for fetching and caching, and
`presentation/shared/utils/weather/` for localization. Weather DTOs and service
contracts were not changed by this folder cleanup.

Group-role labels, policies, ID normalization, and the presence-role adapter live
directly in `presentation/utils/roles/`. The adapter stays in presentation because
it maps service presence roles to the existing UI role type.

Different avatar implementations remain separate; moving them together does not
merge their rendering, loading, or caching behavior.
