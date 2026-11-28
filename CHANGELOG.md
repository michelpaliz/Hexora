# Hexora Flutter Changelog

Development changes are recorded here. Customer facing copy is prepared separately under `release-notes/` and requires review before publication.

## Unreleased

### Feature

- Added compact News & Updates panels to authentication and Home, plus a complete bilingual news history with category filters and pagination. (`hexora-news-updates`)
- Added a protected platform administrator interface for preparing, previewing, publishing, and archiving announcements. (`hexora-news-updates`)
- Added business level invoice language selection and applied it to invoice editing and preview flows. (`multilingual-invoices`)

### Improvement

- Ask mode offers editable Spanish and English question suggestions for income, expenses, unpaid invoices and income by client. Structured answer tables and summaries format monetary values using the interface language and currency. (`insights-question-suggestions`)

- Manual expense creation now shows expandable progress steps, explains unavailable steps, and reuses save validation before review while preserving the draft and document preview. (`expense-creation-stepper`)

- Desktop chat now follows the shared workspace menu layout: white sidebar, compact conversation rows with blue selection and unread badges, and tabs beside the sidebar.

- Chat exposes new team conversations, incidents and member access directly in the workspace sidebar, including icon-only navigation, according to the user's permissions.

- Workspace utility buttons use evenly spaced standalone icons with individual interaction states, and the member icon opens the Members area while showing live online presence. The bottom navigation has a clean upper edge without a divider above the Hexora logo.

- Home opens the complete news history in a responsive dialog, preserving the current workspace instead of navigating to a separate legacy screen.

- Recurring invoice details use a continuous pale background with distinct white cards and a separate save bar, removing the large white outer frame.

- Home now groups business search and news in a responsive overview with a pale blue surface, profile completion, useful shortcuts and an accessible quick guide. Its workspace dashboard now also provides a collapsible, in-page sidebar for quickly reaching business details, financial information, activity, tasks, documents and news. (`home-workspace-overview`)

- Web sign-in and registration use a pale blue background, clear Hexora branding, a business introduction with feature tiles, and news alongside the authentication form.

- Announcement loading failures remain isolated from authentication and Home so users can continue working normally. (`hexora-news-updates`)
- Business profile loading now uses a subtle pulsing skeleton and animated status instead of legacy spinners.
- Event creation now opens a compact editor from calendar time slots, expands without losing entered information, and adapts between a side panel, dialog, and full-screen layout. (`responsive-calendar-event-editor`)
- Email verification now uses the same responsive, branded experience as login and registration, with clearer status feedback and actions on desktop and mobile. (`consistent-email-verification`)
- Business onboarding now adapts to each setup step, with clearer progress, compact forms, and accessible actions on every screen size. (`compact-business-onboarding`)
- Expanded unified navigation now labels the module selector clearly while retaining its compact icon-only control when collapsed.
- Simplified the Gastos navigation by temporarily hiding unfinished tax-form tools.
- Supplier-invoice totals now remain visible in a sticky footer aligned with their table columns while reviewing expenses.

### Bug Fix

- Map client panels, dialogs and dropdowns receive clicks instead of passing them to the map underneath; map interaction resumes when popups close.

- Chat keeps a single workspace tab row beside its menu, including after layout changes during hot reload.

- The workspace Members shortcut now opens the existing member-management section with its sidebar, instead of the legacy full-page card. Members uses a single workspace menu without a duplicated tab row.
- Prevented invoice creation from retaining another business's issuer or customer context after switching businesses.
- Kept the authentication news area visible when no announcement has been published and placed it beside the form on wide screens. (`hexora-news-updates`)
- Prevented Flutter Web text fields from losing their active editing element when expanding, saving, or closing the calendar event editor. (`responsive-calendar-event-editor`)
