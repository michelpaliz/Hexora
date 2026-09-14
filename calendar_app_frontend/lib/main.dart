import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hexora/app/bootstrapp/app_bootstrap.dart';
import 'package:hexora/app/init_main.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auht_gate.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/c-frontend/routes/routes.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/f-themes/app_colors/themes/theme_provider/theme_provider.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/l10n.dart';
import 'package:provider/provider.dart';

const String _appBuildTag = String.fromEnvironment('APP_BUILD_TAG');

Future<void> main() async {
  await startApp();
}

Future<void> startApp({
  Future<void> Function()? initializeServices,
  void Function(Widget app)? runApplication,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialize = initializeServices ?? initializeAppServices;
  final launch = runApplication ?? runApp;

  try {
    await initialize();

    // Quick visibility into which API the app is targeting at runtime.
    // Remove or adjust as needed for production logging policies.
    debugPrint('ðŸ“¡ API base: ${ApiConstants.baseUrl}');
    debugPrint('ðŸ“¦ CDN base: ${ApiConstants.cdnBaseUrl}');
    if (_appBuildTag.isNotEmpty) {
      debugPrint('ðŸ§± Build tag: $_appBuildTag');
    }

    launch(const HexoraApp());
  } catch (error, stackTrace) {
    debugPrint('App startup failed: $error\n$stackTrace');
    launch(
      _StartupErrorApp(
        onRetry: () => startApp(
          initializeServices: initialize,
          runApplication: launch,
        ),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
      home: _StartupErrorScreen(onRetry: onRetry),
    );
  }
}

class _StartupErrorScreen extends StatefulWidget {
  const _StartupErrorScreen({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<_StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<_StartupErrorScreen> {
  var _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await widget.onRetry();
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                localizations.somethingWentWrong,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isRetrying ? null : _retry,
                child: _isRetrying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(localizations.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HexoraApp extends StatelessWidget {
  const HexoraApp({super.key, this.shell});

  final Widget? shell;

  @override
  Widget build(BuildContext context) {
    return AppBootstrap(
      child: shell ?? const _AppShell(),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    AuthenticatedHttpClient.setSessionExpiredHandler(
        SessionExpiryHandler.handle);

    return Consumer2<ThemeModeProvider, LocaleProvider>(
      builder: (context, themeModeProvider, localeProvider, _) {
        return MaterialApp(
          navigatorKey: SessionExpiryHandler.navigatorKey,
          locale: localeProvider.locale,
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
          // Allow deep links (e.g., /verify-email) to become the initial route.
          onGenerateRoute: (settings) {
            final name = settings.name;
            final path = name == null ? null : Uri.tryParse(name)?.path;
            String? normalizedPath = path ?? name;
            if (normalizedPath != null &&
                normalizedPath.startsWith('/hexora/')) {
              normalizedPath = normalizedPath.substring('/hexora'.length);
            }
            if (normalizedPath == '/hexora') {
              normalizedPath = '/';
            }
            final builder = routes[normalizedPath];
            if (builder != null) {
              return MaterialPageRoute(
                builder: builder,
                settings: settings,
              );
            }
            // Fallback to auth gate if route not found
            return MaterialPageRoute(
              builder: (_) => const AuthGate(),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
