# Native mobile design

`AppTheme` selects `MobileTheme` only for native Android and iOS. Web (including
mobile browsers) and native desktop retain the existing light/dark themes.
The saved light/dark/system preference continues to apply.

Use theme roles rather than literal colors:

| Element | Theme role |
| --- | --- |
| Screen and header | `surface` / `scaffoldBackgroundColor` |
| Card or grouped list | `surfaceContainerLow` |
| Sheet, dialog, menu | `surfaceContainerHigh` |
| Divider | `outlineVariant` |
| Input outline | `outline` |
| Body and secondary text | `onSurface`, `onSurfaceVariant` |
| Primary action | `primary`, `onPrimary` |
| Selected filter or tab container | `primaryContainer`, `onPrimaryContainer` |
| Error | `errorContainer`, `onErrorContainer` |
| Success / pending | `MobileStatusColors.success` / `.warning` |

Use 16 px screen/card padding, 24 px section spacing, 16 px card corners,
16 px body text and 14 px metadata. Standard buttons and icon buttons have
48 px minimum targets. Allow text scaling and wrapping; respect safe areas.
Keep status labels or symbols alongside status colors.

When a shared widget needs a mobile-only adjustment, check
`MobileTheme.isActive(context)`. Do not change the legacy palette or branch on
screen width alone: a narrow browser must retain its existing theme.

Regression coverage: `test/theme/mobile_theme_test.dart` verifies platform
isolation and text contrast; `test/presentation/banking/banking_mobile_theme_test.dart`
checks filters and layout at 320 px with 100% and 200% text scaling.
