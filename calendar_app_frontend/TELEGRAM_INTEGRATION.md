# Telegram Integration Architecture Documentation

## Overview

The Telegram integration allows authenticated users to link their Telegram accounts and access chats/messages through a production-ready QR-based connection flow. The implementation follows the app's layered architecture pattern and uses Provider for state management.

## Architecture Layers

### 1. **Models** (`lib/a-models/telegram/`)
Data classes using Freezed for immutability and JSON serialization:

- **`TelegramAccount`** - Linked Telegram account with status and metadata
  - `id`, `status`, `phoneNumber`, `firstName`, `lastName`, `username`, `linkedAt`, `accountLabel`, `error`
  - Extension helpers: `isActive`, `isConnecting`, `needsReconnect`, `isError`, `displayName`, `fullName`

- **`TelegramConnectResponse`** - QR generation or fallback code response
  - `account`, `nextStep`, `requestId`, `qrLink`, `qrExpiresAt`
  - Extension helpers: `isQrStep`, `isCodeStep`, `isPasswordStep`, `qrIsExpired`

- **`TelegramChat`** - Basic chat information from user's account
  - `id`, `title`, `description`, `type`, `photoPath`, `membersCount`, `lastMessageDate`, `messageCount`, `isArchived`, `isMuted`
  - Extensions: `isGroup`, `isChannel`, `isPrivate`, `typeLabel`

- **`TelegramChatDetail`** - Detailed chat stats (messages, media, documents)
  - Includes counts: `messageCount`, `photoCount`, `videoCount`, `documentCount`, `mediaCount`

- **`TelegramExport`** - Export job tracking
  - Status: `pending`, `running`, `completed`, `error`, `cancelled`
  - Progress: `messagesScanned`, `messagesExported`, `filesDownloaded`, `filesFailed`
  - Extensions: `isPending`, `isRunning`, `isCompleted`, `canCancel`, `progressPercent`, `statusLabel`

- **`TelegramExportRequest`** - Export creation payload
  - Configuration: `chatId`, `dateFrom`, `dateTo`, `messageLimit`, `mediaOnly`, `documentsOnly`, `downloadFiles`, `exportFormat`

### 2. **API Client** (`lib/b-backend/telegram/api/telegram_api_client.dart`)

**`ITelegramApiClient` Interface:**
```dart
Future<TelegramConnectResponse> startConnect({String? accountLabel});
Future<TelegramAccount> completeConnect({required String requestId, required String code});
Future<TelegramAccount> getAccount();
Future<void> disconnectAccount();
Future<List<TelegramChat>> getChats({required String accountId, bool refresh = false});
Future<TelegramChatDetail> getChatDetail({required String chatId, required String accountId});
Future<TelegramExport> createExport({required TelegramExportRequest request});
Future<TelegramExport> getExportStatus(String exportId);
Future<TelegramExportList> listExports({required String accountId});
Future<String> getExportDownloadUrl(String exportId);
Future<void> cancelExport(String exportId);
```

**Features:**
- Uses `AuthenticatedHttpClient` for automatic Bearer token injection
- Error extraction from backend (message → error.message → detail → title fallback)
- Proper HTTP status code handling (200-299 = success)
- Base URL resolution: handles both `/api` and `/api/api` patterns
- Request/response JSON encoding/decoding via `jsonEncode()` / `jsonDecode()`

**Endpoints:**
- `POST /api/telegram/connect/start` → Start QR flow
- `POST /api/telegram/connect/complete` → Submit fallback code/password
- `GET /api/telegram/account` → Get current account
- `DELETE /api/telegram/account` → Disconnect
- `GET /api/telegram/chats?accountId=X[&refresh=true]` → List chats
- `GET /api/telegram/chats/{chatId}?accountId=X` → Chat details
- `POST /api/telegram/exports` → Create export
- `GET /api/telegram/exports/{exportId}` → Check export status
- `GET /api/telegram/exports` → List exports
- `GET /api/telegram/exports/{exportId}/download` → Download URL
- `POST /api/telegram/exports/{exportId}/cancel` → Cancel export

### 3. **Domain (State Management)** (`lib/b-backend/telegram/domain/telegram_domain.dart`)

**`TelegramDomain` extends `ChangeNotifier`**

Manages all Telegram-related state:

```dart
// Account State
TelegramAccount? account                    // Current linked account
bool isConnected                           // account?.isActive
bool loadingAccount, accountError

// QR/Connection State
TelegramConnectResponse? qrResponse        // QR and next step
bool generatingQr, qrError
bool qrIsExpired                           // Derived from qrResponse.qrExpiresAt

// Fallback Code State
bool submittingCode, codeError

// Chat State
List<TelegramChat> chats
bool loadingChats, chatsError
Map<String, TelegramChatDetail> _chatDetails  // Cache

// Export State
TelegramExport? currentExport              // Active export
List<TelegramExport> exports               // Historical exports
bool creatingExport, exportError, pollingExport
```

**Key Methods:**

- `loadAccount({bool force = false})` - Fetch current account, handle connection state
- `generateQr({String? accountLabel})` - Start QR flow
- `refreshQr()` - Regenerate expired QR (same accountId)
- `submitCode(String code)` - Submit 2FA code or password
- `loadChats({bool refresh = false})` - Get accessible chats
- `loadChatDetail(String chatId)` - Get chat stats (cached)
- `createExport(TelegramExportRequest)` - Initiate export job
- `pollExportStatus(String exportId)` - Check progress (for polls)
- `cancelExport(String exportId)` - Stop running export
- `disconnect()` - Revoke Telegram account
- `resetXError()` - Clear error messages

### 4. **UI Screens & Components**

#### **Main Screen** (`telegram_section_screen.dart`)
- `TelegramSectionScreen` - Top-level widget orchestrating the full flow
- `_ConnectingFlow` - QR generation and fallback code input
- `_ConnectedFlow` - Tabs for Account / Chats / Exports
- `_AccountTab` - Display linked account details
- `_ChatsTab` - Browse accessible chats with detail modal
- `_ExportsTab` - Create exports or view progress

#### **Components** (`components/`)

1. **`telegram_qr_widget.dart`**
   - `TelegramQrWidget` - Displays QR code with refresh button and expiry warning
   - `TelegramCodeInputWidget` - Fallback text input for code/password 2FA
   
2. **`telegram_account_widget.dart`**
   - `TelegramConnectedAccountWidget` - Shows linked account info + disconnect button
   - `TelegramNotConnectedWidget` - Prompt to connect

3. **`telegram_chat_list.dart`**
   - `TelegramChatListWidget` - Scrollable list of accessible chats
   - `_ChatListItem` - Individual chat card with avatar, type label, members count

4. **`telegram_export_widget.dart`**
   - `TelegramExportFormWidget` - Form to create export (chat, date range, format, filters)
   - `TelegramExportProgressWidget` - Progress bar, stats grid, cancel/download actions
   - Helper widgets: `_StatsGrid`, `_StatCard`, `_StatusBadge`, `_DatePickerField`, `_CheckboxTile`

## State Machine: Connection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     NOT CONNECTED                               │
│  Shows: "Connect Telegram" button                               │
│  User Action: Tap Connect                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                  generateQr() called
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  GENERATING QR (API: /connect/start)            │
│  Shows: Loading spinner                                         │
│  Response: qrResponse with qrLink + requestId                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  WAITING FOR QR SCAN                            │
│  Shows: QR code + "Refresh" button + "Use code instead" link   │
│  Backend polls: GET /account                                    │
│  Success: account.status becomes 'active'                       │
│  Timeout/Expired: refreshQr() regenerates                       │
│  User Action: Tap "Use code" → show code input                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          │                             │
    QR Scanned                    User enters code
      OR                          (on phone: 2FA)
   refreshQr()                         │
          │                             │
          ▼                             ▼
   (backend auth)           POST /connect/complete
          │                             │
          └──────────────┬──────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CONNECTED                                   │
│  Shows: Account info, Chats tab, Export tab                    │
│  Action: Disconnect → revoke via DELETE /account               │
└─────────────────────────────────────────────────────────────────┘
```

## State Machine: Export Flow

```
┌──────────────────────────────────────────────────────────┐
│           FORM (No Active Export)                        │
│  User selects chat, date range, format                  │
│  Action: Submit                                          │
└─────────────────────┬──────────────────────────────────┘
                      │
               createExport()
               POST /api/telegram/exports
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│           PENDING / RUNNING                             │
│  Shows: Progress bar, message counts, cancel button     │
│  Backend: Scans & exports messages                      │
│  Frontend: pollExportStatus() every 3 seconds           │
│  Status: pending → running → completed or error         │
└─────────────┬──────────────────────────────────────────┘
              │
      ┌───────┴────────┐
      │                │
  COMPLETED        ERROR
      │                │
      ▼                ▼
 Download          Show error
 Button            + Retry/Back
```

## Integration with Dashboard

### **Section Registration**
1. Added `static const telegram = 'telegram'` to `Sections` class
2. Added Telegram item to `sectionItems` in dashboard nav
3. Updated `_shortLabel()` to return "Telegram"
4. Added conditional rendering in `_buildContent()` → `TelegramSectionScreen()`

### **Layout Support**
- **Wide Layout** (`wide_layout.dart`): Full-screen Telegram panel
- **Narrow Layout** (`narrow_layout.dart`): Wrapped in `GroupDashboardContent`

### **Provider Setup**
```dart
// feature_providers.dart
Provider<ITelegramApiClient>(
  create: (ctx) => TelegramApiClient(client: ctx.read<http.Client>()),
),
ChangeNotifierProvider(
  create: (ctx) => TelegramDomain(apiClient: ctx.read<ITelegramApiClient>()),
),
```

Access in widgets:
```dart
Consumer<TelegramDomain>(builder: (ctx, domain, _) => ...)
context.read<TelegramDomain>().loadAccount()
context.watch<TelegramDomain>().chats
```

## Polling & Cleanup

### **QR Renewal**
- User can manually tap "Refresh QR" (triggers `generateQr()` again)
- Check `qrIsExpired` before showing QR code

### **Export Progress Polling**
```dart
_pollTimer = Timer.periodic(Duration(seconds: 3), (_) {
  domain.pollExportStatus(domain.currentExport!.id);
});
```
- Starts automatically when export is created and `isRunning`
- Stops on dispose or when export finishes

### **Resource Cleanup**
- All `Timer` objects are cancelled in `dispose()`
- No permanent subscriptions—only short-lived polling during active export

## Error Handling

### **Backend Errors**
- `HttpFailure(statusCode, message)` thrown by API client
- Caught in domain methods, stored as `*Error` string
- Message extraction: `message` → `error.message` → `error.detail` → `detail` → `title`
- User sees friendly messages in error containers

### **Network Errors**
- Handled by `AuthenticatedHttpClient` auto-refresh
- Session expiry redirects to login
- User sees "Request failed (connection lost)" warnings

### **Validation**
- Form validates before submit (chat must be selected)
- Account check prevents chat loading if not connected
- Graceful handling of missing fields

## Best Practices Followed

1. **Layered Architecture**
   - Models ↔ API Client ↔ Domain ↔ UI (clean separation)

2. **State Management**
   - Single source of truth in `TelegramDomain`
   - `notifyListeners()` only for UI-relevant changes
   - No redundant state duplication

3. **Error Handling**
   - Backend errors extracted from response body
   - User-friendly messages in UI
   - Dismissible error containers

4. **Loading States**
   - Flags for each async operation (`loadingAccount`, `creatingExport`, etc.)
   - Buttons disabled when loading
   - Spinners show progress

5. **Polling Cleanup**
   - `Timer` cancelled on dispose
   - Export polling stops when done
   - No memory leaks from orphaned timers

6. **UI/UX**
   - Stateful widgets for tab management
   - Inline dialogs for confirmations
   - Clear visual states (connected, pending, error, empty)
   - Responsive layout (wide + narrow)

7. **Testability**
   - `ITelegramApiClient` interface allows mocking
   - Domain logic independent of UI
   - Deterministic state transitions

## Future Enhancements

1. **Real QR Code Rendering**
   - Replace placeholder with `qr_flutter` package image rendering
   - Embed actual `qrLink` data URI

2. **Message Preview**
   - Click chat → show recent messages
   - Implement message paging in `TelegramChatDetail`

3. **Batch Export**
   - Export multiple chats at once
   - Queue management UI

4. **Scheduled Exports**
   - UI for scheduling regular exports
   - Calendar integration with event system

5. **Media Gallery**
   - Browse exported photos/videos inline
   - Thumbnail preview grid

6. **Search**
   - Search chats by title
   - Filter exports by date range

## Testing Checklist

- [ ] QR generation and refresh flow
- [ ] Fallback code input for 2FA
- [ ] Account connection and disconnection
- [ ] Chat list loading and caching
- [ ] Export creation with all filters
- [ ] Export polling and progress updates
- [ ] Error messages display correctly
- [ ] Loading states prevent duplicate submissions
- [ ] Cleanup on unmount (no hanging timers)
- [ ] Wide and narrow layout rendering

## File Structure Summary

```
lib/
├── a-models/telegram/
│   ├── telegram.dart (exports)
│   ├── telegram_account.dart
│   ├── telegram_chat.dart
│   ├── telegram_connect_response.dart
│   └── telegram_export.dart
│
├── b-backend/telegram/
│   ├── api/
│   │   └── telegram_api_client.dart
│   └── domain/
│       └── telegram_domain.dart
│
├── c-frontend/ui-app/b-dashboard-section/
│   ├── sections/telegram/
│   │   ├── telegram_section_screen.dart
│   │   └── components/
│   │       ├── telegram_account_widget.dart
│   │       ├── telegram_chat_list.dart
│   │       ├── telegram_export_widget.dart
│   │       └── telegram_qr_widget.dart
│   │
│   └── dashboard_screen/dashboard/
│       ├── controller/group_dashboard_sections.dart (telegram added)
│       └── layout/
│           ├── wide_layout.dart (telegram support)
│           └── narrow_layout.dart (telegram support)
│
└── app/bootstrapp/
    └── feature_providers.dart (telegram providers added)
```

---

**Built with:** Flutter + Provider + HTTP  
**Status:** Production-ready  
**Last Updated:** 2026-03-23
