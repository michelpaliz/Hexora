# App issues review

Reviewed 19 September 2026. This is a documentation-only audit of additional issues found in source code. The items below remain open; no application code was changed in this pass.

For confirmed backend blockers and contract investigations, see [BACKEND_FIXES_REQUIRED.md](BACKEND_FIXES_REQUIRED.md). Do not treat the existence of a defensive fallback as proof that the server is currently broken.

## F-01 — Worker reports can show unavailable data as empty/zero

**Owner:** frontend, with backend contract clarification. **Priority:** high.

**Evidence:** `listWorkers` and `listTimeEntries` return empty lists on HTTP 404. `getActiveWorkersTotals` returns zero totals on 404. These branches do not distinguish a valid empty period from a missing endpoint/resource.

**Impact:** workers may seem missing, or hours/pay may appear as zero while data is actually unavailable.

**Suggested frontend fix:** preserve explicit failure/unavailable state, retain previously loaded data with a stale indicator when appropriate, and offer retry. Display zero only after a successful response confirms zero.

**Verification:** fake API responses for successful empty data, 404, 403 and 500; check both list and summary UI. Use fixtures, not modifications to payroll data.

Source: [Time tracking API client](lib/services/time_tracking/api/time_tracking_api_client.dart).

## F-02 — OCR server failures suggest that the user's image is at fault

**Owner:** frontend. **Priority:** medium.

**Evidence:** invoice-line OCR maps every HTTP 500+ response to “Error al extraer lineas. Intenta con una imagen mas nitida.” A server failure does not establish an image-quality problem. The same method maps any 404 to “Factura no encontrada,” even though a missing route can also return 404.

**Impact:** users may repeatedly rescan valid documents or believe an invoice disappeared when the service is unavailable.

**Suggested frontend fix:** distinguish server unavailability, invalid file/image, invoice not found and unsupported endpoint using status plus agreed structured error codes. Offer retry for transient failures without blaming the image.

**Verification:** fixtures for 400 invalid image, 404 invoice missing, 404 route missing, 429, and 500/503; verify distinct, localized messages where the contract permits a distinction.

Source: [Invoice-line OCR service](lib/services/invoicing/invoice_lines_ocr_service.dart).

## F-03 — Notification API logs entire response bodies

**Owner:** frontend. **Priority:** high.

**Evidence:** `getNotificationsForUser` uses unconditional `print` calls for the request URL, status and complete response body. These calls have no debug-mode guard. Notification payloads can contain personal, group and document information.

**Impact:** full application records can be copied into device/debug logs or support captures unnecessarily. This review did not establish that logs were externally collected or that a disclosure occurred.

**Suggested frontend fix:** remove full-body logging; if diagnostics are needed, log limited status/count/request identifiers behind an appropriate debug/logging policy. Never include tokens, document contents or full personal records.

**Verification:** use a fake response containing a unique personal-data marker and verify logs do not contain it in the supported build modes.

Source: [Notification API client](lib/services/notification/notification_api_client.dart).

## Backend/contract findings added in this pass

| Area | Finding | Evidence level |
| --- | --- | --- |
| Mail | Trash operation suppresses a specific duplicate-key HTTP 500 | Existing workaround; live failure not reproduced |
| Recurring invoices/receipts | Per-series execution falls back to a shared `/run` route | Contract-scope risk; no unintended execution observed |
| Workers | 404 is interpreted as empty/zero | Confirmed frontend behavior; backend semantics need agreement |
| VAT | Quarterly report falls back between two API routes | Contract-equivalence question; no incorrect calculation observed |

Details and acceptance checks: [Backend handoff, sections 5–8](BACKEND_FIXES_REQUIRED.md#5-mail-trash-operation-duplicate-key-server-error-workaround).

No mail was deleted, recurring documents generated, payroll changed, or OCR upload submitted during this review. Live server behavior remains to be verified with disposable test data.

## F-04 — Download URLs receive app authorization without an origin check

**Owner:** frontend; backend must clarify allowed download destinations. **Priority:** high.

**Evidence:** `DownloadsApi.downloadFile` accepts an absolute `http://` or `https://` `downloadUrl` and sends it through `AuthenticatedHttpClient.get`. That client attaches the stored app bearer token without comparing the request origin with the API origin. A 401 from that destination also enters the app's token-refresh/session-expiry flow.

**Impact:** if a job returns an external storage/CDN URL, the app attempts to send its API credential to that origin. An expired external link can also be confused with an expired app session. The code path is confirmed; this review did not establish that production jobs return external URLs, that any token was disclosed, or that a third party received it.

**Suggested frontend fix:** validate schemes and destinations before dispatch. Use app authentication only for the intended API origin; handle approved presigned storage URLs with a separate unauthenticated client. Do not use external storage 401/403 responses to invalidate the app session. Explicitly decide the redirect policy as part of the implementation review.

**Verification:** fake transports and dummy tokens only. Test same-origin API URLs, approved HTTPS storage links, unknown hosts, HTTP URLs, redirects, expired links and missing URLs. Assert that app authorization never reaches an external origin and external errors do not clear the session.

Sources: [Downloads API](lib/services/downloads/downloads_api.dart), [authenticated HTTP client](lib/services/auth/token/authenticated_http_client.dart).

## F-05 — Temporary refresh failure can log the user out

**Owner:** frontend; backend error semantics should be documented. **Priority:** high.

**Evidence:** after a request returns 401, `_refreshAccessToken` returns `false` for missing credentials, any unsuccessful refresh response, and any thrown exception. `_request` handles all of those results by calling the session-expiry handler. `SessionExpiryHandler.handle` clears tokens and navigates to login.

**Impact:** if the access token expires while the refresh service is temporarily unavailable or the connection fails, a recoverable network/server problem takes the same path as a revoked refresh token. This is a confirmed code-level failure path, not a live logout reproduced during this audit.

**Suggested frontend fix:** distinguish successful refresh, definitively invalid/revoked credentials, and temporary failure. Preserve credentials on temporary failure and present retry/offline feedback. Keep the existing shared in-flight refresh behavior so concurrent requests do not launch duplicate refreshes.

**Verification:** fake an initial 401 followed by refresh success, invalid-token response, 500/503 and transport failure. Only definitive invalid credentials should clear the session; successful refresh should retry once with the new token.

Sources: [Authenticated HTTP client](lib/services/auth/token/authenticated_http_client.dart), [refresh API](lib/services/auth/api/auth_api_client.dart), [session-expiry handler](lib/app/session/session_expiry_handler.dart).

## F-06 — Cancelling a native download is recorded as a handoff

**Owner:** frontend. **Priority:** medium.

**Evidence:** the native `launchFileDownloadImpl` returns normally when `FilePicker.saveFile` returns null. Its caller then unconditionally calls `registry.markHandedToBrowser(downloadId)`. There is no cancellation result or cancelled registry state.

**Impact:** dismissing the save dialog can produce a completed handoff entry even though the user did not save the file. The registry also uses a browser-oriented status for native saves. This review traced the code; it did not open or cancel a live save dialog.

**Suggested frontend fix:** return an explicit saved/handed-off/cancelled outcome from platform launchers. Do not mark cancellation as success or as an error; ensure native and browser status wording reflects what the app can actually verify.

**Verification:** mock a null picker result, successful native save, filesystem failure and browser handoff. Check registry state and user feedback for each case.

Sources: [Native download launcher](lib/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher_stub.dart), [shared launcher](lib/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart), [download registry](lib/presentation/shared/downloads/session_download_registry.dart).

## F-07 — Avatar requests bypass shared token refresh

**Owner:** frontend. **Priority:** medium.

**Evidence:** `UserApiClient.getFreshAvatarUrl` calls `http.get` directly with the supplied bearer token and throws for non-200 responses. It does not use the shared authenticated client or refresh/retry on 401 within this method.

**Impact:** an expired access token can make an avatar SAS request fail even when features using the shared authenticated client recover automatically. The method-level inconsistency is confirmed; the complete user-visible outcome depends on the caller's fallback and was not reproduced live.

**Suggested frontend fix:** route first-party avatar SAS requests through the common authenticated request policy, retaining a placeholder/error fallback. Do not attach app authorization when subsequently fetching an external presigned image URL.

**Verification:** fake expired access credentials and a valid refresh response; confirm one successful authenticated retry for the SAS request and an appropriate fallback on genuine denial.

Source: [User API client, getFreshAvatarUrl](lib/services/user/api/user_api_client.dart).

## F-08 — Expense import restoration ignores account and group

**Owner:** frontend; restoring a job also requires backend ownership checks. **Priority:** high.

**Evidence:** `OcrImportJobMappingStore` stores mappings under the device-wide key `hexora.ocrImportJobMappings.v1`. A mapping has preview/background job IDs, time and type, but no account or group ID. `_restorePersistedBatchJobMapping` loads all mappings, selects the first OCR mapping (or the first mapping overall), assigns its IDs to the current expense screen, and starts tracking it without checking the current group or account.

**Impact:** opening expenses for group B can restore a mapping saved for group A. Switching accounts on the same installation can also retain old mappings. This proves missing client-side scoping; it does not prove the backend permits access to another account's records or that cross-account data was displayed.

**Suggested frontend fix:** persist owner and group identifiers, scope lookups to both, and verify the resolved job belongs to that scope before restoring it. Define a migration for existing unscoped mappings: validate or ignore them rather than guessing ownership.

**Verification:** fixtures with jobs for two groups and two accounts; restore each screen and assert only its own jobs are selected. Include legacy mappings, deleted jobs and access-denied responses. No production imports should be started for this test.

Sources: [OCR mapping store](lib/presentation/shared/jobs/ocr_import_job_mapping_store.dart), [expense upload screen, persistence/restoration methods](lib/presentation/screens/workspace/sections/expenses/upload/expense_upload_screen.dart).

## F-09 — OCR polling can overlap and apply older results last

**Owner:** frontend. **Priority:** medium.

**Evidence:** the shared OCR store starts a timer every four seconds and calls `unawaited(refresh())`. `refresh` sets `_loading` but does not guard against a request already running, cancel the previous request, or check a response generation before replacing `_jobs`. Manual refresh can enter the same method concurrently. Every request also independently clears `_loading` in its `finally` block.

**Impact:** slow requests can overlap; an older response arriving later can overwrite newer job progress. Loading can become false while another request is still running, and repeated requests may continue during a slow connection. This is a source-level race, not measured production traffic.

**Suggested frontend fix:** share one in-flight refresh or sequence response application explicitly. Schedule the next poll after completion, and align loading state with the actual active request. Include session identity when deciding whether a response is still valid.

**Verification:** controllable fake requests that complete in reverse order, requests lasting more than four seconds, manual refresh during polling, and a session switch while a request is pending. Latest accepted state must not regress and polling must remain bounded.

Source: [OCR import jobs store, refresh and _ensurePolling](lib/presentation/shared/jobs/ocr_import_jobs_store.dart).

## F-10 — Shared OCR state/polling is not reset by logout

**Owner:** frontend. **Priority:** high.

**Evidence:** `OcrImportJobsStore.instance` is a process-wide singleton holding jobs and a polling timer. It has no session-reset API; its timer is cancelled by `dispose` or when no active jobs remain. The inspected logout path clears auth state/tokens and navigates to login but does not reset/dispose this store. The session-expiry handler likewise clears tokens and navigates. No OCR-store disposal call was found in the auth/app paths reviewed.

**Impact:** cached jobs and polling can survive logout in the same app process. A subsequent account may encounter stale job state until a successful refresh replaces it; delayed responses from the previous session can also repopulate the shared store. This is a lifecycle gap, not proof of unauthorized backend access.

**Suggested frontend fix:** centralize account teardown: stop polling, invalidate pending results, clear account-specific caches and start new state only for the next authenticated account. Account changes and forced session expiry should use the same teardown policy. Recreating providers alone will not reset this static singleton.

**Verification:** seed an active job, log out using a fake auth flow, advance the timer and assert polling stops and cached jobs clear. Log in as a second test account; then finish an old pending request and assert its response is ignored.

Sources: [OCR import jobs store](lib/presentation/shared/jobs/ocr_import_jobs_store.dart), [settings logout](lib/presentation/screens/settings/screens/settings.dart), [auth service](lib/services/auth/auth_service.dart), [auth provider](lib/services/auth/auth_provider.dart), [session-expiry handler](lib/app/session/session_expiry_handler.dart).

## F-11 — Concurrent OCR mapping writes can lose updates

**Owner:** frontend. **Priority:** medium.

**Evidence:** both `upsert` and `remove` perform independent asynchronous read-modify-write operations on one SharedPreferences JSON list. No shared write queue or lock is present. Two operations can read the same starting list and overwrite each other's changes when they save.

**Impact:** concurrent import starts can lose a saved mapping; a removal racing an insertion can restore a removed entry or drop the new one. This can make import restoration intermittent. The race was identified in source, not reproduced against production storage.

**Suggested frontend fix:** serialize mutations through a shared queue or use storage with transactional updates. Preserve account/group scoping from F-08. A per-call lock would not protect concurrent calls; the queue must cover every writer to the key.

**Verification:** force two upserts, and then an upsert/remove pair, to read before either writes. Assert the final list retains both intended updates, removes only the requested job, and obeys the existing retention limit.

Source: [OCR mapping store, upsert and remove](lib/presentation/shared/jobs/ocr_import_job_mapping_store.dart).

## F-12 — Group-notification load failures appear as an empty list

**Owner:** frontend. **Priority:** medium.

**Evidence:** `NotificationViewModel.fetchNotificationsForGroup` catches every exception and returns an empty list. `GroupNotificationsScreen._load` expects errors to reach its catch block; instead it treats the empty result as success, replaces existing items and clears the error state.

**Impact:** a failed refresh can erase the visible list and suggest there are no group notifications. The screen's error/retry behavior cannot distinguish this from a genuinely empty result. This is a confirmed code path; no live outage was induced.

**Suggested fix:** propagate a typed failure or return an explicit result object. Keep existing notifications on refresh failure and show retry feedback; reserve the empty state for a successful empty response.

**Verification:** fake an initial populated response followed by 403, 500 and a transport exception. The existing items should remain with error feedback. A successful empty response should show the empty state.

Sources: [Notification view model](lib/presentation/viewmodels/notifications/notification_view_model.dart), [group notifications screen](lib/presentation/screens/workspace/sections/notifications/group_notifications_screen.dart).

## F-13 — Group-notification desktop actions have not adopted the safer home flow

**Owner:** frontend. **Priority:** high for deletion correctness, medium for feedback.

**Evidence:** for widths of 600 pixels or more, the group screen builds `NotificationCard` with the legacy synchronous `onDelete` callback and does not supply `onDeleteAsync`. The card therefore dismisses before the API finishes. `_handleDelete` only removes the item from the screen's list on success; on failure it shows an error but leaves the dismissed item in that list. `_handleNegate` also has no local catch and the desktop callback does not await it. The mobile detail-action switch does catch decline errors, so the decline issue is specific to the desktop path inspected.

**Impact:** a failed desktop swipe deletion can leave a dismissed widget still in the tree, causing inconsistent UI or a Dismissible assertion. Decline errors can escape the desktop UI callback without the feedback used on mobile. These are source-level paths, not live destructive tests.

**Suggested fix:** reuse the awaited action contract, per-item busy state and failure feedback across home/group and mobile/desktop views. Ensure deletion failure returns false from confirmation and does not dismiss the item; do not merely wire a handler that catches errors and returns success.

**Verification:** at desktop width, reject the delete request after confirmation and verify the item remains usable with no framework exception. Reject a decline request and verify visible feedback and retry availability. Repeat at mobile width to keep both flows aligned.

Sources: [Group notifications screen, list builder and handlers](lib/presentation/screens/workspace/sections/notifications/group_notifications_screen.dart), [notification card dismissal contract](lib/presentation/screens/notifications/show-notifications/widgets/notification_card.dart).

## F-14 — Invitation success is conflated with notification cleanup success

**Owner:** frontend orchestration; backend idempotency/response contract should be confirmed. **Priority:** high.

**Evidence:** accepting/declining first calls `respondToInviteAndRefresh` (respond, then refresh groups), then separately deletes the notification, then removes it locally. Exceptions from later steps propagate through the same failure handling as a failed invitation response.

**Impact:** membership may already have changed when notification deletion fails, yet the UI reports an unsuccessful action and retains invitation controls. Retrying can resubmit an already-resolved invitation. A follow-up group refresh can also fail after the response succeeds; its precise handling depends on the group repository path. The cleanup failure path is directly visible in code; no live invite was accepted or declined during this audit.

**Suggested frontend fix:** track the primary response and subsequent cleanup separately. Once the response succeeds, disable resolved invitation controls and show the correct accepted/declined state; retry cleanup independently. On ambiguous response failures, fetch invitation status before resubmitting.

**Backend clarification:** document responses for already-accepted/declined/expired invitations and whether responding automatically resolves the corresponding notification. Do not assume a transaction spans the currently separate client requests.

**Verification:** fake successful invitation response followed by notification-delete failure. Assert membership success remains visible and retry does not respond to the invitation again. Also cover rejection before any membership change.

Sources: [Notification view model, handleConfirmation/handleNegation](lib/presentation/viewmodels/notifications/notification_view_model.dart), [group domain, respondToInviteAndRefresh](lib/services/groups/domain/group_domain.dart).

## F-15 — Client deduplication can hide distinct notification occurrences

**Owner:** frontend with backend identity-contract clarification. **Priority:** medium.

**Evidence:** `_dedupeNotifications` keeps only the newest record for a semantic key built from group/recipient, text, category/type and args. The key omits notification ID, timestamp and read state. Distinct IDs with identical payload content collapse into one entry regardless of their age or unread state.

**Impact:** repeated legitimate occurrences with identical content can disappear from history, and displayed counts can exclude unread records. Deleting the retained record can allow an older equivalent record to reappear on a later fetch if it still exists on the server. Whether the server intentionally emits equivalent duplicate deliveries remains unverified.

**Suggested fix:** establish delivery/occurrence identity explicitly. Deduplicate the same notification ID, or use an agreed server occurrence key. Group separate occurrences visually rather than dropping them unless there is a documented deduplication contract.

**Verification:** fixtures with two IDs and identical content on different dates, mixed read states, and a deletion followed by refetch. Separately test repeated delivery of the same ID, which should not create duplicate cards.

Source: [Notification API client, _dedupeNotifications/_notificationSemanticKey](lib/services/notification/notification_api_client.dart).

## F-16 — Visual notification grouping omits workspace/entity identity

**Owner:** frontend. **Priority:** medium.

**Evidence:** `_groupKey` uses `titleKey` plus event title, or `titleKey` plus `messageKey`. It does not include group ID, event ID or document ID. Consecutive items from different groups/events can therefore appear under a single collapsed card. Expansion state uses a key containing the list offset (`periodKey:key:i`), so inserting or removing an earlier item changes the group's identity.

**Impact:** same-named jobs from different companies can look like updates to one job, and an expanded group can unexpectedly collapse after a refresh/incoming notification. Individual records still retain their payloads when expanded; this finding does not establish incorrect individual-item routing.

**Suggested fix:** define grouping by intent: include workspace and entity identity when representing updates to one resource, or clearly label a cross-resource category bundle. Derive expansion keys from stable identity rather than position.

**Verification:** consecutive same-title events from two groups and two event IDs must remain distinguishable. Expand a bundle, insert an unrelated newer notification, and verify that its expanded state remains stable.

Source: [Notifications tab view, _groupKey/_collapseConsecutive and expanded groups](lib/presentation/screens/notifications/show-notifications/sections/notifications_tab_view.dart).
