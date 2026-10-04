# Backend fixes required

Backend handoff from the frontend review on **19 September 2026**.

This file records observations from this development session, not a fresh production health check. No backend changes were made. Confirmed API symptoms are separated from suspected contract gaps and untested flows; a frontend workaround does not mean the backend issue is resolved.

Additional source review: mail, recurring documents, workers, VAT, OCR and logging. These findings below are **code observations**, not new confirmed production failures. Frontend-owned findings are in [APP_ISSUES_REVIEW.md](APP_ISSUES_REVIEW.md).

## Priority overview

| Priority | Issue | Evidence/status |
| --- | --- | --- |
| High | Service indoor/outdoor fields missing from API responses | Confirmed response gap; persistence needs backend investigation |
| High | Operational weather analysis endpoint unavailable | Authenticated request returned HTTP 404 |
| Medium | Import notifications may lack a resolvable group destination | Frontend failure path found; affected backend records need verification |
| Medium | Notification categories do not consistently match the content | Observed on the emulator; confirm intended classification |

## 1. Persist and return service environment fields

**User impact:** changing a service to Exterior does not reliably appear after saving/reloading. Previously, missing values were displayed as Interior.

**Observed:** the service-list response inspected during this session contained four service records, all without `workEnvironment` and `weatherSensitive`. This proves a response-contract gap; it does not establish whether the database, write handler, or response serializer is responsible.

**Backend work:**

- Check create/update validation, persistence, and response serialization for `workEnvironment` (`indoor`, `outdoor`, `mixed`) and `weatherSensitive` (boolean).
- Return these fields consistently from create, PATCH, list, and detail endpoints under `/services`.
- Decide how existing records should represent an unknown environment. Do not silently classify historical records as indoor without a product/data decision.

**Frontend workaround:** missing environment values display as “Entorno sin especificar.” The editor compares the PATCH response with the selected values and refuses to announce a successful save if they differ. The create flow was not verified with the same response safeguard.

**Acceptance check:** create and edit test services for all three environments and both sensitivity values; verify PATCH response, subsequent GET/list response, app restart, and another device all show the saved values.

Code references:

- [Service API](lib/services/service_catalog/service_api_client.dart)
- [Service model](lib/models/service_catalog/service.dart)
- [Service editor and response validation](lib/presentation/screens/workspace/sections/services_clients/sheets/add_service_sheet.dart)

## 2. Restore operational weather analysis

**User impact:** the dashboard can display the general forecast but cannot analyze weather risks for scheduled outdoor work.

**Observed:** an authenticated request to `/api/weather/work-conditions/{groupId}` returned **404**. The regular Denia weather endpoint returned **200**, so general forecast availability does not demonstrate that work-condition analysis is deployed.

**Backend work:** verify route registration, deployed version, gateway routing, authorization, and group support for:

```text
GET /api/weather/work-conditions/{groupId}?from=<UTC ISO timestamp>&to=<UTC ISO timestamp>
```

The current frontend expects `rating`, `affectedVisitCount`, `outdoorVisitCount`, `unavailableLocationCount`, `reasons`, and `affectedVisits`. The model linked below defines nested visit/weather fields. Confirm the contract with the backend rather than returning placeholder success data.

**Frontend workaround:** 404/501 use general weather with “Previsión general · Sin análisis de trabajos.” Only 404 was observed; 501 is a defensive fallback, not a confirmed server response.

**Acceptance check:** an authorized group request returns the agreed JSON; indoor/outdoor services and weather-sensitive visits affect results correctly; missing locations and empty schedules have explicit behavior.

Code references:

- [Work conditions API](lib/services/weather/work_conditions_api.dart)
- [Response model](lib/models/weather/work_condition_result.dart)
- [Dashboard weather card](lib/presentation/screens/workspace/sections/weather/work_conditions_card.dart)

## 3. Verify import-notification destination data

**Status: needs backend verification, not a confirmed universal backend defect.**

The frontend resolves an import notification through its `jobId`, fetches the job, and looks for a group identifier in metadata/result data. Its local import mapping stores job identifiers but does not provide the missing group. Without a resolvable group, the app cannot safely choose a workspace.

**Backend investigation:** inspect affected OCR notifications and referenced jobs. Ensure the authorized job response exposes its group, or agree on an explicit group field in the notification contract. Verify `actionUrl`, job status, and job retention remain sufficient to open review/results for historical notifications. Never substitute an arbitrary current group.

**Frontend behavior:** missing destinations now produce an error instead of silently doing nothing. Errors opening imports are caught; repeated taps are guarded.

**Acceptance check:** test completed, review-required, in-progress, deleted/expired, and inaccessible jobs, including after reinstall when local mappings are absent.

Code references:

- [Notification navigation and import handlers](lib/presentation/screens/notifications/show-notifications/show_notifications.dart)
- [Job notification model](lib/models/jobs/job_notification.dart)
- [Local import mapping](lib/presentation/shared/jobs/ocr_import_job_mapping_store.dart)

## 4. Confirm notification category semantics

**Observed:** the Usuario tab contained bank-expense alerts, while Sistema contained completed-event alerts. The frontend currently maps backend category values into broad tabs; these placements may reflect legacy producer behavior or an intentional contract.

**Backend/product work:** agree on categories for each producer before changing historical data. Check numeric enum compatibility, event creation/completion notifications, bank alerts, and invitation payloads. Do not blindly renumber persisted categories.

**Frontend workaround:** navigation follows explicit notification keys/payloads rather than relying only on the tab. Known legacy invitation keys remain actionable. Deleted-resource messages remain informational.

**Acceptance check:** new notifications appear in the agreed tab, older payloads still render, and routing remains correct across all 15 category values.

Code references:

- [Category enum](lib/models/notifications/notification_user.dart)
- [Broad tab mapping](lib/presentation/enums/category/broad_category.dart)
- [Destination policy](lib/presentation/screens/notifications/show-notifications/utils/notification_destination.dart)

## 5. Mail trash operation: duplicate-key server error workaround

**Status: evidenced by an existing client workaround; not reproduced against the server during this review.**

`MailApiClient.trash` catches HTTP 500 containing `E11000 duplicate key error`, `folder_1_imapuid_1`, and `inbox.trash`, then treats it as success. The code comment attributes this to messages already present in Trash. A client-side text match cannot prove the server/mailbox state is correct.

**Backend investigation:** inspect the trash/move implementation and database uniqueness rules. Repeated requests for an already-trashed message should have an explicit idempotent result, with database and mailbox state consistent. Do not blindly drop a database index as a fix.

**Acceptance check:** using disposable messages, trash once, repeat, and issue concurrent requests; verify final folders and stored records, then refresh from another client. No raw database exception should be returned as a successful operation's response.

Source: [Mail API, trash handler and duplicate-error matcher](lib/services/mail/api/mail_api_client.dart).

## 6. Recurring invoice/receipt execution: verify fallback scope

**Status: contract risk found in code; no incorrect document generation was observed or triggered.**

Both recurring APIs first POST to `/{seriesId}/run`. On 404/405 they POST to `/run` with `{"seriesId":"..."}`. The same API classes also expose a no-body `/run` method. The frontend cannot establish that every deployed fallback handler respects the supplied series ID.

**Backend investigation:** confirm the fallback endpoint executes only the requested series, enforces access, and rejects unknown/invalid IDs rather than defaulting to a wider run. Confirm the distinction between missing route, missing series, and unsupported method. Review idempotency for retries.

**Acceptance check:** with two disposable series A/B, exercise both route variants for A; B must remain unchanged. Test missing IDs, inaccessible series and repeated requests. Do not test this by generating production invoices or receipts.

Sources: [Recurring invoices API](lib/services/invoicing/recurring_invoices_api.dart), [recurring receipts API](lib/services/receipts/recurring_receipts_api.dart).

## 7. Worker endpoints: agree on empty versus unavailable responses

**Status: confirmed frontend fallback behavior; backend outage or missing deployment not reproduced. Shared ownership.**

Worker/time-entry lists turn HTTP 404 into empty lists. Active-worker totals turn 404 into zero counts, hours and pay. This can make a missing route, unavailable group or unsupported feature look like a valid empty report.

**Backend contract work:** document when these endpoints return 404 and how a successfully queried empty period is represented. Prefer an explicit successful empty response for valid empty data and distinguish unsupported/missing resources from it. Check `/groups/{groupId}/time-tracking/workers`, `/time-entries`, and `/totals/active-workers`.

**Frontend work:** show unavailable/error status instead of interpreting every 404 as zero work. This portion is fixable in Flutter and is tracked in [App issues review](APP_ISSUES_REVIEW.md).

**Acceptance check:** distinguish valid empty period, invalid group, forbidden access and missing route; unavailable data must not be presented as confirmed zero work or pay.

Source: [Time tracking API client](lib/services/time_tracking/api/time_tracking_api_client.dart).

## 8. VAT summary: verify fallback contract equivalence

**Status: compatibility question found in code, not a confirmed calculation or server error.**

The quarterly summary tries `/vat-audit/summary` and on 404 retries `/vat/summary`, passing year, quarter (`T1`–`T4`) and optional group. A fallback is safe only if both endpoints agree on scope and response semantics.

**Backend investigation:** confirm group authorization, period boundaries, supported parameters and returned field meanings for both routes. Document which route is canonical and whether 404 means missing route or missing data. No tax/calculation correctness conclusion was made in this review.

**Acceptance check:** run both routes against the same test dataset, group and quarter and compare the agreed contract. A fallback must not silently broaden the group scope or return an incompatible summary.

Source: [VAT summary API](lib/services/vat/vat_summary_api.dart).

## Verification still needed — not confirmed backend bugs

Use test accounts and disposable records for these checks:

- Accept/decline real invitations, including expired invites and permission failures.
- Persist notification read/delete actions, then verify from another device.
- Complete authenticated PDF/ZIP downloads and test expired or inaccessible links.
- Upload event evidence, register its association, and complete an eligible event with required photos.

The event inspected earlier could not be managed by the current user under the existing creator/assigned-recipient policy. That is **not evidence of a backend defect**. If administrators should also upload evidence or complete it, agree on the authorization policy and enforce it on the backend; do not bypass it in the UI.

## Already fixed in the frontend — no backend ticket needed

- Mobile notification/document navigation and initial financial tab/detail selection.
- Missing read buttons, small tap targets, disabled-action handling, and duplicate taps.
- Swipe confirmation, failed-request feedback, local deletion/list mutability, and read-state handling.
- Empty/loading states, refresh reconciliation, and profile count sourcing.
- Mobile greeting, profile, notification, and dashboard layout improvements.

Frontend tests validate local behavior and payload handling. They do not prove deployment, persistence, permissions, or end-to-end backend success.

## Contract clarifications from the download/session audit

These are **not additional confirmed backend failures**. The frontend issues are tracked as F-04–F-07 in [APP_ISSUES_REVIEW.md](APP_ISSUES_REVIEW.md).

- **Download destinations:** document whether `downloadUrl` is a relative API route, a same-origin authenticated route, or an external presigned HTTPS URL. List permitted storage origins, expiry behavior and whether refresh of an expired link is supported. The frontend must enforce credential boundaries; the server returning a URL does not make it safe to attach an app token to that URL.
- **Refresh failure semantics:** distinguish invalid/revoked refresh credentials from temporary service failures using stable status/error codes. The frontend currently treats both as session expiry and needs its own fix.
- **Native save cancellation and avatar retry:** these are frontend-owned issues, not backend implementation requests.

## Account/workspace restoration audit — frontend ownership

Additional issues F-08–F-11 in [APP_ISSUES_REVIEW.md](APP_ISSUES_REVIEW.md) concern unscoped local OCR mappings, concurrent polling, logout cleanup and concurrent local storage writes. These require frontend changes and are **not evidence that backend authorization is broken**. Backend verification should still confirm that every preview/background job lookup enforces the authenticated account's access and exposes the group identity needed for safe restoration, as discussed in section 3.

## Notification lifecycle contract questions from the continued audit

These are investigation questions, not newly reproduced backend failures. Frontend findings F-12–F-16 are documented in [APP_ISSUES_REVIEW.md](APP_ISSUES_REVIEW.md).

- **Invitation resolution:** confirm idempotent behavior for already-resolved invites and whether accepting/declining also resolves its notification. The current client makes separate response and notification-delete requests; partial-success handling needs a frontend fix.
- **Notification identity:** confirm whether repeated equivalent payloads are separate occurrences or duplicate deliveries. Supply a stable occurrence/delivery key if deduplication beyond the notification ID is required. The client currently drops equivalent records without a time boundary.
- **Group-screen errors and visual grouping:** these are frontend-owned action/state issues, not reasons to change backend membership authorization or category values.
