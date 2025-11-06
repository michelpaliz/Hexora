import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hexora/app/bootstrapp/app_bootstrap.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/helper/auht_gate.dart';
import 'package:hexora/c-frontend/f-notification-section/show-notifications/notify_phone/local_notification_helper.dart';
import 'package:hexora/c-frontend/routes/routes.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:hexora/d-local-stateManagement/theme/theme_provider.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/l10n.dart';
import 'package:hexora/utils/init_main.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppServices();
  await setupLocalNotifications();

  runApp(const HexoraApp());
}

class HexoraApp extends StatelessWidget {
  const HexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBootstrap(
      child: const _AppShell(),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeModeProvider, LocaleProvider>(
      builder: (context, themeModeProvider, localeProvider, _) {
        return MaterialApp(
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
          home: const AuthGate(),
        );
      },
    );
  }
}
