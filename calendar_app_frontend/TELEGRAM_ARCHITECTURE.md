# Telegram Integration - Architecture Diagram

## Layered Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE                             │
│  TelegramSectionScreen                                              │
│  ├─ _ConnectingFlow        ┌──────────────┐ ┌─────────────────────┐│
│  │  (QR + code input)     │ QR Widget    │ │ Code Input Widget  ││
│  │                        └──────────────┘ └─────────────────────┘│
│  │                                                                 │
│  └─ _ConnectedFlow         ┌──────────────┐ ┌────────────────────┐│
│     (Account/Chats/Exports)│ Account Card │ │ Chat List Widget   ││
│                            └──────────────┘ └────────────────────┘│
│                            ┌────────────────────────────────────────┐│
│                            │ Export Form + Progress Widget           ││
│                            └────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Consumer<TelegramDomain>
                                    │
┌─────────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT (Provider)                    │
│                                                                      │
│  TelegramDomain (ChangeNotifier)                                    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ State Properties:                                            │   │
│  │  • account, isConnected, loadingAccount, accountError        │   │
│  │  • qrResponse, generatingQr, qrError, qrIsExpired           │   │
│  │  • chats, loadingChats, chatsError, _chatDetails            │   │
│  │  • currentExport, creatingExport, pollingExport, exportError │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Methods:                                                            │
│  ├─ loadAccount()        → GET /account                            │
│  ├─ generateQr()         → POST /connect/start                     │
│  ├─ submitCode()         → POST /connect/complete                  │
│  ├─ loadChats()          → GET /chats                              │
│  ├─ createExport()       → POST /exports                           │
│  ├─ pollExportStatus()   → GET /exports/{id} (3s timer)           │
│  └─ disconnect()         → DELETE /account                         │
│                                                                      │
│  Notifies UI on state changes via notifyListeners()                │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ IApiClient Interface
                                    │
┌─────────────────────────────────────────────────────────────────────┐
│                         API CLIENT LAYER                            │
│                                                                      │
│  TelegramApiClient (implements ITelegramApiClient)                 │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ • Uses AuthenticatedHttpClient (auto Bearer token)          │   │
│  │ • Base URL: {ApiConstants.baseUrl}/telegram                 │   │
│  │ • JSON encode/decode via jsonEncode/jsonDecode              │   │
│  │ • Error extraction: Try message → error.message → detail │   │
│  │ • HTTP 200-299 = success, else HttpFailure exception       │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP Requests
                                    │
┌─────────────────────────────────────────────────────────────────────┐
│                        BACKEND API ENDPOINTS                        │
│                                                                      │
│  POST   /api/telegram/connect/start              ← Generate QR    │
│  POST   /api/telegram/connect/complete           ← Submit code    │
│  GET    /api/telegram/account                    ← Account status │
│  DELETE /api/telegram/account                    ← Disconnect     │
│  GET    /api/telegram/chats?accountId=X          ← List chats    │
│  GET    /api/telegram/chats/{chatId}?accountId=X ← Chat details  │
│  POST   /api/telegram/exports                    ← Create export  │
│  GET    /api/telegram/exports/{id}               ← Status check   │
│  GET    /api/telegram/exports/{id}/download      ← Download URL   │
│  POST   /api/telegram/exports/{id}/cancel        ← Cancel export  │
│                                                                      │
│  All authenticated with Bearer token (auto-injected)               │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Models

```
TelegramConnectResponse
├─ account: TelegramAccount
├─ nextStep: 'scan_qr' | 'submit_code' | 'submit_password'
├─ requestId: String
├─ qrLink: String?
└─ qrExpiresAt: DateTime?

TelegramAccount
├─ id: String
├─ status: 'awaiting_qr' | 'active' | 'reconnect_required' | 'error'
├─ phoneNumber: String?
├─ firstName: String?
├─ lastName: String?
├─ username: String?
├─ linkedAt: DateTime?
└─ accountLabel: String?

TelegramChat
├─ id: String
├─ title: String
├─ type: 'private' | 'group' | 'supergroup' | 'channel'
├─ membersCount: int?
├─ messageCount: int?
└─ description: String?

TelegramChatDetail extends TelegramChat
├─ messageCount: int
├─ photoCount: int
├─ videoCount: int
├─ documentCount: int
└─ mediaCount: int

TelegramExport
├─ id: String
├─ status: 'pending' | 'running' | 'completed' | 'error' | 'cancelled'
├─ messagesScanned: int
├─ messagesExported: int
├─ filesDownloaded: int
├─ filesFailed: int
├─ totalMessages: int?
├─ exportFormat: 'json' | 'json_with_media' | 'html' | 'csv'
└─ downloadUrl: String?

TelegramExportRequest
├─ chatId: String
├─ accountId: String
├─ dateFrom: DateTime?
├─ dateTo: DateTime?
├─ messageLimit: int?
├─ mediaOnly: bool?
├─ documentsOnly: bool?
├─ downloadFiles: bool?
└─ exportFormat: String
```

## State Transitions

### Connection State Machine

```
┌─────────────────┐
│  NOT CONNECTED  │ ← Initial state, account == null
└────────┬────────┘
         │ generateQr()
         ▼
┌─────────────────────────────────────┐
│ GENERATING QR (generatingQr=true)   │
│ POST /api/telegram/connect/start    │
└────────┬────────────────────────────┘
         │ Success: qrResponse set
         ▼
┌─────────────────────────────────────┐
│ WAITING FOR SCAN  (qrResponse≠null) │
│ Shows: QR code + refresh button     │
│ User: Scan or tap "use code"        │
└─┬──────────────────────────────────┬┘
  │ User scans on phone               │ User taps "use code"
  │ (backend auth completes)          │
  │                                   ▼
  │                    ┌──────────────────────┐
  │                    │ CODE INPUT MODE      │
  │                    │ TelegramCodeInputWidget
  │                    └──────────┬───────────┘
  │                              │ submitCode()
  │                              │ POST /connect/complete
  │                              ▼
  └─────────────┬─────────────────┘
                │ Backend returns account with status='active'
                │ loadAccount() triggered
                ▼
        ┌──────────────┐
        │  CONNECTED   │
        │ account≠null │
        │ isConnected  │
        └──────────────┘
           │
           ├─→ loadChats()
           ├─→ Show tabs
           └─→ Enable export

Disconnect:
        ┌──────────────┐
        │  CONNECTED   │
        └──────┬───────┘
               │ disconnect()
               │ DELETE /account
               ▼
        ┌─────────────┐
        │ NOT CONNECTED
        └─────────────┘
```

### Export State Machine

```
┌─────────────────────────┐
│ NO ACTIVE EXPORT        │
│ currentExport == null   │
│ Show: Export form       │
└────────┬────────────────┘
         │ User selects chat, dates, format
         │ onSubmit()
         │
         ▼
┌─────────────────────────────────────┐
│ CREATING EXPORT                     │
│ creatingExport = true               │
│ POST /api/telegram/exports          │
└────────┬────────────────────────────┘
         │ Response: TelegramExport
         │ currentExport = export
         │
         ▼
┌─────────────────────────────────────┐
│ PENDING / RUNNING                   │
│ currentExport.status ∈              │
│   ['pending', 'running']            │
│ Show: Progress bar + stats          │
│ Timer: pollExportStatus() every 3s  │
└────────┬────────────────────────────┘
         │
         ├─ COMPLETED ──→ ┌──────────────┐
         │                │ Completed    │
         │                │ Show download│
         │                └──────────────┘
         │
         └─ ERROR ──────→ ┌──────────────┐
         │                │ Error msg    │
         │                │ Retry/back   │
         │                └──────────────┘
         │
         └─ CANCELLED ──→ ┌──────────────┐
                          │ Cancelled    │
                          │ New export?  │
                          └──────────────┘
```

## Polling Lifecycle

```
                    TelegramSectionScreen._ConnectedFlowState
                                  │
                        ┌─────────┴────────┐
                        │                  │
                    initState()        dispose()
                        │                  │
         ┌──────────────┘                  │
         │                                 │
    Check for active export                │
    if (currentExport?.isRunning)          │
         │                                 │
         ▼                                 │
    Timer.periodic(3s) ────────────────┐  │
         │                             │  │
         └─→ pollExportStatus(id)  ┌───┘  │
             updates currentExport │      │
             notifyListeners()     │      │
                                   │  ┌───┘
                     When export:  │  │
                     • completes ──┘  │
                     • errors ────────┘
                     • cancelled ─────┘
                     
                     Timer.cancel()
                     → No memory leak
```

## File Structure

```
telegram_integration/
│
├── Models (lib/a-models/telegram/)
│   ├── telegram_account.dart              (Account + extensions)
│   ├── telegram_connect_response.dart      (QR response)
│   ├── telegram_chat.dart                  (Chat + Detail)
│   ├── telegram_export.dart                (Export + Request + List)
│   └── telegram.dart                       (Barrel export)
│
├── Backend API (lib/b-backend/telegram/)
│   ├── api/
│   │   └── telegram_api_client.dart        (ITelegramApiClient + impl)
│   └── domain/
│       └── telegram_domain.dart            (ChangeNotifier state mgnt)
│
├── Frontend UI (lib/c-frontend/...)
│   ├── sections/telegram/
│   │   ├── telegram_section_screen.dart    (Main orchestrator)
│   │   └── components/
│   │       ├── telegram_qr_widget.dart     (QR + code input)
│   │       ├── telegram_account_widget.dart(Account display)
│   │       ├── telegram_chat_list.dart     (Chat list)
│   │       └── telegram_export_widget.dart (Export form + progress)
│   │
│   └── dashboard_screen/dashboard/
│       ├── controller/
│       │   └── group_dashboard_sections.dart (Added: telegram constant)
│       └── layout/
│           ├── wide_layout.dart            (Added: Telegram inline)
│           └── narrow_layout.dart          (Added: Telegram wrapper)
│
├── Providers (lib/app/bootstrapp/)
│   └── feature_providers.dart              (Added: TelegramApiClient, TelegramDomain)
│
└── Documentation
    ├── TELEGRAM_INTEGRATION.md             (Full architecture)
    └── TELEGRAM_QUICK_START.md             (User guide)
```

---

Built with: **Provider + HTTP + Freezed** | Status: **Production Ready** ✅
