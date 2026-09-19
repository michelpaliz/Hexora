You’re basically there 🙌. Quick final checklist to make sure nothing bites you later:

### Backend

* [ ] **Routes mounted:** In `server.js`, you added
  `app.use("/api/blob", require("./routes/blob_routes/userBlobRoute"));` and
  `app.use("/api/blob", require("./routes/blob_routes/groupBlobRoute"));`
* [ ] **Generic service:** `services/azureBlob.js` uses `{ scope, resourceId }` and (optionally) `strategy: 'versioned'`.
* [ ] **AuthZ checks:** In `groupBlobRoute`, verify owner/admin before issuing SAS or deleting blobs.
* [ ] **Models:**

  * User: has `photoUrl` + `photoBlobName`.
  * Group: has `photoUrl` + `photoBlobName` and your `fromJSON`/`toJSON` aligned.
* [ ] **Group schema fromJSON:** Accepts `photoUrl` and `photoBlobName` (you already tweaked earlier).
* [ ] **CORS for storage (if direct GETs from CDN/Blob):** Set allowed origins if you’re doing private `read-sas` from app.
* [ ] **Env vars:** `AZURE_STORAGE_ACCOUNT_URL`, `AZURE_STORAGE_ACCOUNT_NAME`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_STORAGE_CONTAINER`, `SAS_UPLOAD_MINUTES`, `SAS_READ_MINUTES`.

### Frontend (Flutter)

* [ ] **ApiConstants:** has `baseUrl`, `cdnBaseUrl`, and `avatarsArePublic`.
* [ ] **Shared uploader:** `blob_uploader.dart` in place; used by:

  * [ ] `MyHeaderDrawer` → `uploadImageToAzure(scope: 'users', ...)` (done).
  * [ ] `EditGroupBody` → `uploadImageToAzure(scope: 'groups', resourceId: group.id, ...)` (done).
  * [ ] **Create Group** flow → create first, then upload, then PATCH (done in controller).
* [ ] **Group model:** renamed to `photoUrl`, added `photoBlobName`, added `copyWith` (done).
* [ ] **groupDomain:** added `updateGroupPhoto(...)` to update local state instantly (added).
* [ ] **UserAvatar widget:** still fine; uses `photoUrl` or calls `_fetchReadSas` if needed (good).

### Optional but recommended

* [ ] **Versioned filenames** (`strategy: 'versioned'`) to avoid CDN cache busting issues (you set this in the helper).
* [ ] **Old blob cleanup:** If you switch to versioned, optionally delete the previous blob when you PATCH a new one.
* [ ] **Client-side compression:** Resize/compress before upload to speed things up (e.g., `image` or `flutter_image_compress`).
* [ ] **Mobile permissions:** Ensure iOS `Info.plist` and Android `AndroidManifest.xml` have photo library permissions for `image_picker`.
* [ ] **UX polish:** Show a small loading spinner on avatars during upload (you added one on group edit; consider for user avatar too).
* [ ] **Security:** Consider IP pinning in SAS (your service has commented `SASIPRange`), and keep short expirations.

### Smoke test plan (5 mins)

1. Create a group **without** selecting an image → should succeed.
2. Edit the same group → pick an image → see instant new photo; refresh app to confirm persistence.
3. Change user avatar → see immediate update; verify in DB `photoBlobName` is stored.
4. If avatarsArePublic=false → confirm `read-sas` endpoint returns a short-lived URL and it loads.

If any of these fail, tell me which step and the error you see (status code + message), and I’ll zero in on it.
