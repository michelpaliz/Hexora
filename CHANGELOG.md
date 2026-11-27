# Hexora Flutter Changelog

Development changes are recorded here. Customer facing copy is prepared separately under `release-notes/` and requires review before publication.

## Unreleased

### Feature

- Added compact News & Updates panels to authentication and Home, plus a complete bilingual news history with category filters and pagination. (`hexora-news-updates`)
- Added a protected platform administrator interface for preparing, previewing, publishing, and archiving announcements. (`hexora-news-updates`)
- Added business level invoice language selection and applied it to invoice editing and preview flows. (`multilingual-invoices`)

### Improvement

- Announcement loading failures remain isolated from authentication and Home so users can continue working normally. (`hexora-news-updates`)

### Bug Fix

- Prevented invoice creation from retaining another business's issuer or customer context after switching businesses.
