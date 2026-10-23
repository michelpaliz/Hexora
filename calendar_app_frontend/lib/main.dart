import 'package:flutter/foundation.dart'
    show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hexora/app/bootstrap/app_bootstrap.dart';
import 'package:hexora/app/init_main.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/presentation/screens/auth/auth_gate.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/presentation/routes/routes.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/notify_phone/local_notification_helper.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/l10n.dart';
import 'package:provider/provider.dart';

const String _appBuildTag = String.fromEnvironment('APP_BUILD_TAG');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter'],
        await rootBundle.loadString('assets/fonts/inter/LICENSE.txt'));
  });
  await initializeAppServices();
  await setupLocalNotifications();

  // Quick visibility into which API the app is targeting at runtime.
  // Remove or adjust as needed for production logging policies.
  debugPrint('ðŸ“¡ API base: ${ApiConstants.baseUrl}');
  debugPrint('ðŸ“¦ CDN base: ${ApiConstants.cdnBaseUrl}');
  if (_appBuildTag.isNotEmpty) {
    debugPrint('ðŸ§± Build tag: $_appBuildTag');
  }

  runApp(const HexoraApp());
}

class HexoraApp extends StatelessWidget {
  const HexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBootstrap(
      child: _AppShell(),
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
          // Flutter otherwise starts at `/` and AuthGate masks browser deep
          // links such as `/hexora/reset-password?token=...`.
          initialRoute: _browserInitialRoute(),
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

String _browserInitialRoute() {
  final uri = Uri.base;
  var path = uri.path;
  if (path == '/hexora' || path == '/hexora/') path = '/';
  if (path.startsWith('/hexora/')) {
    path = path.substring('/hexora'.length);
  }
  if (path.isEmpty) path = '/';
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '$path$query';
}
