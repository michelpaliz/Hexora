import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/api/auth_api_client.dart';
// ---- Auth + User (interfaces) ----------------------------------------------
import 'package:hexora/b-backend/auth_user/auth/auth_database/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/helper/auht_gate.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/token/token_storage.dart';
import 'package:hexora/b-backend/auth_user/user/api/i_user_api_client.dart';
import 'package:hexora/b-backend/auth_user/user/api/user_api_client.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/auth_user/user/presence_domain.dart';
import 'package:hexora/b-backend/auth_user/user/repository/i_user_repository.dart';
import 'package:hexora/b-backend/auth_user/user/repository/user_repository.dart';
import 'package:hexora/b-backend/business_logic/worker/api/i_time_tracking_api_client.dart';
import 'package:hexora/b-backend/business_logic/worker/api/time_tracking_api_client.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/api/event_api_client.dart';
// ---- Events (interfaces) ----------------------------------------------------
import 'package:hexora/b-backend/group_mng_flow/event/api/i_event_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/resolver/event_group_resolver.dart';
import 'package:hexora/b-backend/group_mng_flow/group/api/group_api_client.dart';
// ---- Groups (interfaces) ----------------------------------------------------
import 'package:hexora/b-backend/group_mng_flow/group/api/i_group_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/repository/group_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/group/repository/i_group_repository.dart';
// ---- Invites ---------------------------------------------------------------
import 'package:hexora/b-backend/group_mng_flow/invite/api/invite_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/domain/invite_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
// ---- Recurrence rules -------------------------------------------------------
import 'package:hexora/b-backend/group_mng_flow/recurrenceRule/recurrence_rule_api_client.dart';
// ---- Notifications + theming + locale --------------------------------------
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/f-notification-section/show-notifications/notify_phone/local_notification_helper.dart';
import 'package:hexora/c-frontend/routes/routes.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:hexora/d-local-stateManagement/theme/theme_provider.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
// ---- i18n + boot ------------------------------------------------------------
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/l10n.dart';
import 'package:hexora/utils/init_main.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppServices();
  await setupLocalNotifications();

  runApp(
    MultiProvider(
      providers: [
        // 0) Singleton app state that others read
        ChangeNotifierProvider(create: (_) => NotificationDomain()),

        // 1) USER (interfaces) — token directly from TokenStorage to avoid cycles
        Provider<IUserApiClient>(create: (_) => UserApiClient()),
        Provider<IUserRepository>(
          create: (ctx) => UserRepository(
            apiClient: ctx.read<IUserApiClient>(),
            tokenSupplier: () =>
                TokenStorage.loadToken(), // ✅ no AuthService here
          ),
        ),
        // (A) API client
        Provider<ITimeTrackingApiClient>(
          create: (_) => TimeTrackingApiClient(), // <-- your concrete impl
        ),

        // (B) Repository that GroupTimeTrackingScreen reads
        Provider<ITimeTrackingRepository>(
          create: (ctx) => TimeTrackingRepository(
            ctx.read<ITimeTrackingApiClient>(),
          ),
        ),

        // 2) Auth stack (Auth API client + provider + service)
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

        // 3) Shared API services (recurrence rules)
        Provider<RecurrenceRuleApiClient>(
            create: (_) => RecurrenceRuleApiClient()),

        // 4) EVENTS (interfaces)
        Provider<IEventApiClient>(
          create: (ctx) => EventApiClient(
            ruleService: ctx.read<RecurrenceRuleApiClient>(),
          ),
        ),
        Provider<IEventRepository>(
          create: (ctx) => EventRepository(
            apiClient: ctx.read<IEventApiClient>(),
            tokenSupplier: () async {
              final token = await ctx.read<AuthService>().getToken();
              if (token == null) throw Exception('Not authenticated');
              return token;
            },
          ),
        ),

        // 5) GROUPS (interfaces)
        Provider<IGroupApiClient>(create: (_) => HttpGroupApiClient()),
        Provider<IGroupRepository>(
          create: (ctx) => GroupRepository(
            apiClient: ctx.read<IGroupApiClient>(),
            tokenSupplier: () async {
              final token = await ctx.read<AuthService>().getToken();
              if (token == null) throw Exception('Not authenticated');
              return token;
            },
          ),
        ),

        // 6) Resolver (hydration/expansion helpers when needed)
        Provider<GroupEventResolver>(
          create: (ctx) => GroupEventResolver(
            ruleService: ctx.read<RecurrenceRuleApiClient>(),
          ),
        ),

        // 7) Invitations
        Provider<InvitationRepository>(
          create: (_) => HttpInvitationRepository(InvitationApiClient()),
        ),
        ChangeNotifierProvider<InvitationDomain>(
          create: (ctx) => InvitationDomain(
            repository: ctx.read<InvitationRepository>(),
            tokenSupplier: () => ctx.read<AuthService>().getToken(),
          ),
        ),

        // 8) App state — reuse the provided NotificationDomain
        ChangeNotifierProvider(
          create: (ctx) => UserDomain(
            userRepository: ctx.read<IUserRepository>(),
            user: null,
            notificationDomain:
                ctx.read<NotificationDomain>(), // ✅ same instance
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => GroupDomain(
            groupRepository: ctx.read<IGroupRepository>(),
            userRepository: ctx.read<IUserRepository>(),
            groupEventResolver: ctx.read<GroupEventResolver>(),
            user: null,
          ),
        ),

        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PresenceDomain()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),

        // 9) EventDomain (depends on IEventRepository + GroupDomain)
        // ProxyProvider2<GroupDomain, IEventRepository, EventDomain?>(
        //   create: (_) => null,
        //   update: (ctx, groupDomain, eventRepo, previous) {
        //     final current = groupDomain.currentGroup;
        //     if (current == null) return null;

        //     final edm = EventDomain(
        //       const [],
        //       context: ctx,
        //       group: current,
        //       repository: eventRepo,
        //       groupDomain: groupDomain,
        //     );
        //     edm.onExternalEventUpdate = previous?.onExternalEventUpdate ??
        //         () => debugPrint(
        //             '⚠️ Default fallback: no calendar UI registered.');
        //     return edm;
        //   },
        // ),

        ProxyProvider2<GroupDomain, IEventRepository, EventDomain?>(
          create: (_) => null,
          update: (ctx, groupDomain, eventRepo, previous) {
            final current = groupDomain.currentGroup;
            if (current == null) return null;

            // ✅ Reuse the previous EventDomain if group is the same.
            if (previous != null && previous.groupId == current.id) {
              return previous;
            }

            // IMPORTANT: Do NOT manually dispose `previous` here.
            // Provider will dispose the old value automatically when a new one is returned.

            final edm = EventDomain(
              const [],
              context: ctx,
              group: current,
              repository: eventRepo,
              groupDomain: groupDomain,
            );

            // keep any hook if you were relying on it
            edm.onExternalEventUpdate = previous?.onExternalEventUpdate ??
                () => debugPrint('⚠️ No calendar UI registered.');
            return edm;
          },
        )
      ],
      child: const MyMaterialApp(),
    ),
  );
}

class MyMaterialApp extends StatelessWidget {
  const MyMaterialApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ⬇️ now consume ThemeModeProvider + LocaleProvider
    return Consumer2<ThemeModeProvider, LocaleProvider>(
      builder: (context, themeModeProvider, localeProvider, _) {
        return MaterialApp(
          locale: localeProvider.locale,
          // ⬇️ provide both themes + the mode
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeModeProvider.mode,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: L10n.all,
          routes: routes,
          home: const AuthGate(),
        );
      },
    );
  }
}
