import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/api/auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/token/token_storage.dart';
import 'package:hexora/b-backend/auth_user/user/api/i_user_api_client.dart';
import 'package:hexora/b-backend/auth_user/user/api/user_api_client.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/auth_user/user/presence_domain.dart';
import 'package:hexora/b-backend/auth_user/user/repository/i_user_repository.dart';
import 'package:hexora/b-backend/auth_user/user/repository/user_repository.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:hexora/d-local-stateManagement/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

final List<SingleChildWidget> coreProviders = [
  // Global app state
  ChangeNotifierProvider(create: (_) => NotificationDomain()),

  // User stack (token from storage)
  Provider<IUserApiClient>(create: (_) => UserApiClient()),
  Provider<IUserRepository>(
    create: (ctx) => UserRepository(
      apiClient: ctx.read<IUserApiClient>(),
      tokenSupplier: () => TokenStorage.loadToken(),
    ),
  ),

  // Auth stack
  Provider<IAuthApiClient>(create: (_) => AuthApiClientImpl()),
  ChangeNotifierProvider<AuthProvider>(
    create: (ctx) => AuthProvider(
      userRepository: ctx.read<IUserRepository>(),
      authApi: ctx.read<IAuthApiClient>(),
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
