# Authentication

Authentication services live here; authentication screens live in
`lib/presentation/screens/auth/`.

| Path | Responsibility |
| --- | --- |
| `auth_provider.dart` | Authentication orchestration and observable state |
| `auth_service.dart` | Existing service facade over the authentication repository |
| `email_verification_state.dart` | Persisted email-verification state |
| `api/` | Authentication API client and interface |
| `repositories/` | Authentication repository contract |
| `models/` | Verification response model |
| `exceptions/` | Existing authentication and password exception types |
| `token/` | Token model, storage interface/implementation, refresh service, authenticated HTTP client |

The token storage interface is `token/i_token_store.dart`; its class remains
`TokenStore`. Token storage keys, secure-storage settings, API endpoints, refresh
behavior, and public class names are unchanged by this folder cleanup.

The existing auth gate is now `presentation/screens/auth/auth_gate.dart`, since
it renders loading/error states and chooses between login and home screens.
Moving it does not change startup wiring or introduce it into another route.
Provider registration remains in `lib/app/bootstrap/`, and session-expiry
handling remains in `lib/app/session/`.

Exception files and provider/service classes remain distinct. This is a path
cleanup, not a consolidation of their behavior.
