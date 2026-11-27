# Hexora Flutter Changelog

Development changes are recorded here. Customer facing copy is prepared separately under `release-notes/` and requires review before publication.

## Unreleased

### Feature

- Added compact News & Updates panels to authentication and Home, plus a complete bilingual news history with category filters and pagination. (`hexora-news-updates`)
- Added a protected platform administrator interface for preparing, previewing, publishing, and archiving announcements. (`hexora-news-updates`)
- Added business level invoice language selection and applied it to invoice editing and preview flows. (`multilingual-invoices`)

### Improvement

- Announcement loading failures remain isolated from authentication and Home so users can continue working normally. (`hexora-news-updates`)
- Business profile loading now uses a subtle pulsing skeleton and animated status instead of legacy spinners.
- Event creation now opens a compact editor from calendar time slots, expands without losing entered information, and adapts between a side panel, dialog, and full-screen layout. (`responsive-calendar-event-editor`)
- Email verification now uses the same responsive, branded experience as login and registration, with clearer status feedback and actions on desktop and mobile. (`consistent-email-verification`)
- Business onboarding now adapts to each setup step, with clearer progress, compact forms, and accessible actions on every screen size. (`compact-business-onboarding`)

### Bug Fix

- Prevented invoice creation from retaining another business's issuer or customer context after switching businesses.
- Kept the authentication news area visible when no announcement has been published and placed it beside the form on wide screens. (`hexora-news-updates`)
- Prevented Flutter Web text fields from losing their active editing element when expanding, saving, or closing the calendar event editor. (`responsive-calendar-event-editor`)
