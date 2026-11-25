import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/presentation/screens/preferences/user_preferences_screen.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('navigation layout cards switch the user preference',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final preferences = UserPreferencesProvider(
      remoteLoader: () async => <String, dynamic>{},
      remoteUpdater: (_) async {},
    );
    await preferences.bindUser('navigation-layout-user');
    addTearDown(preferences.dispose);
    final theme = ThemeModeProvider();
    addTearDown(theme.dispose);
    final locale = LocaleProvider();
    addTearDown(locale.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: preferences),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: locale),
        ],
        child: MaterialApp(
          theme: AppTheme.forPlatform(
            Brightness.light,
            platform: TargetPlatform.windows,
          ),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: UserPreferencesView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diseño de navegación'), findsOneWidget);
    expect(find.text('Menús separados'), findsOneWidget);
    expect(find.text('Menú unificado'), findsOneWidget);
    expect(find.text('Posición de la barra principal'), findsOneWidget);
    expect(find.text('Superior'), findsOneWidget);
    expect(find.text('Inferior'), findsOneWidget);
    expect(preferences.navigationLayout, NavigationLayout.unified);
    expect(preferences.globalHeaderPosition, GlobalHeaderPosition.bottom);

    await tester.tap(find.text('Menús separados'));
    await tester.pumpAndSettle();

    expect(preferences.navigationLayout, NavigationLayout.split);

    await tester.tap(
      find.byKey(const ValueKey('global-header-position-top')),
    );
    await tester.pumpAndSettle();

    expect(preferences.globalHeaderPosition, GlobalHeaderPosition.top);
    expect(tester.takeException(), isNull);
  });
}
