import 'package:hexora/b-backend/auth_user/api/auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/token_store.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/user/api/i_user_api_client.dart';
import 'package:hexora/b-backend/user/api/user_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/b-backend/user/repository/user_repository.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:hexora/f-themes/app_colors/themes/theme_provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

final List<SingleChildWidget> coreProviders = [
  // Global app state
  ChangeNotifierProvider(create: (_) => NotificationDomain()),

  // 🔐 Token store (single source of truth)
  Provider<TokenStore>(create: (_) => SecureTokenStore()),

  // User stack (token from injected store, not static)
  Provider<IUserApiClient>(create: (_) => UserApiClient()),
  Provider<IUserRepository>(
    create: (ctx) => UserRepository(
      apiClient: ctx.read<IUserApiClient>(),
      tokenSupplier: () => ctx.read<TokenStore>().readAccess(), // <-- changed
    ),
  ),

  // Auth stack
  Provider<IAuthApiClient>(create: (_) => AuthApiClientImpl()),
  ChangeNotifierProvider<AuthProvider>(
    create: (ctx) => AuthProvider(
      userRepository: ctx.read<IUserRepository>(),
      authApi: ctx.read<IAuthApiClient>(),
      tokens: ctx.read<TokenStore>(), // <-- inject here
    ),
  ),
  ChangeNotifierProvider<AuthService>(
    create: (ctx) => AuthService(ctx.read<AuthProvider>()),
  ),

  // UserDomain (depends on NotificationDomain + UserRepository)
  ChangeNotifierProvider(
    create: (ctx) => UserDomain(
      userRepository: ctx.read<IUserRepository>(),
      user: null,
      notificationDomain: ctx.read<NotificationDomain>(),
    ),
  ),

  // Presence + theme + locale
  ChangeNotifierProvider(create: (_) => PresenceDomain()),
  ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
  ChangeNotifierProvider(create: (_) => LocaleProvider()),
];
