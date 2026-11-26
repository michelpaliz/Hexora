import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/navigation/shell/hexora_global_nav_bar.dart';
import 'package:hexora/navigation/shell/hexora_quick_settings.dart';
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

  testWidgets(
      'quick settings updates existing providers and invokes settings shortcut',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final preferences = UserPreferencesProvider(
      remoteLoader: () async => <String, dynamic>{},
      remoteUpdater: (_) async {},
    );
    await preferences.bindUser('quick-settings-user');
    addTearDown(preferences.dispose);
    final themeMode = ThemeModeProvider();
    addTearDown(themeMode.dispose);
    await tester.pump();
    var openedAllPreferences = 0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: preferences),
          ChangeNotifierProvider.value(value: themeMode),
        ],
        child: Consumer<ThemeModeProvider>(
          builder: (context, currentTheme, child) => MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.forPlatform(
              Brightness.light,
              platform: TargetPlatform.windows,
            ),
            darkTheme: AppTheme.forPlatform(
              Brightness.dark,
              platform: TargetPlatform.windows,
            ),
            themeMode: currentTheme.mode,
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 56,
                  child: HexoraGlobalNavBar(
                    destinations: const [],
                    activeId: 'invoices',
                    onSelected: (_) {},
                    headerPosition: GlobalHeaderPosition.bottom,
                    quickSettings: HexoraQuickSettingsButton(
                      headerPosition: preferences.globalHeaderPosition,
                      onOpenAllPreferences: () => openedAllPreferences++,
                    ),
                    notificationControl: const SizedBox(
                      key: ValueKey('notification-control'),
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final quickButton = find.byKey(const ValueKey('quick-settings-button'));
    expect(
      tester.getCenter(quickButton).dx,
      lessThan(tester
          .getCenter(find.byKey(
            const ValueKey('notification-control'),
          ))
          .dx),
    );
    expect(find.byTooltip('Ajustes rápidos'), findsOneWidget);

    await tester.tap(quickButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-settings-panel')), findsOneWidget);
    expect(find.text('Menú de navegación'), findsOneWidget);
    expect(find.text('Visualización'), findsOneWidget);
    expect(find.text('Barra principal'), findsOneWidget);
    expect(find.text('Apariencia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('quick-nav-layout-split')));
    await tester.pumpAndSettle();
    expect(preferences.navigationLayout, NavigationLayout.split);

    await tester.tap(
      find.byKey(const ValueKey('quick-nav-display-iconsAndText')),
    );
    await tester.pumpAndSettle();
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsAndText,
    );

    await tester.tap(find.byKey(const ValueKey('quick-header-top')));
    await tester.pumpAndSettle();
    expect(preferences.globalHeaderPosition, GlobalHeaderPosition.top);

    await tester.tap(find.byKey(const ValueKey('quick-theme-lightBlue')));
    await tester.pumpAndSettle();
    expect(themeMode.mode, ThemeMode.light);
    expect(themeMode.lightVariant, LightThemeVariant.blue);

    await tester.tap(find.byKey(const ValueKey('quick-theme-dark')));
    await tester.pumpAndSettle();
    expect(themeMode.mode, ThemeMode.dark);
    expect(find.byKey(const ValueKey('quick-settings-panel')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quick-main-bar-visible')));
    await tester.pumpAndSettle();
    expect(preferences.topNavCollapsed, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('quick-settings-all-preferences')),
    );
    await tester.pumpAndSettle();
    expect(openedAllPreferences, 1);
    expect(find.byKey(const ValueKey('quick-settings-panel')), findsNothing);
  });

  testWidgets('quick settings closes with Escape and outside clicks',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final preferences = UserPreferencesProvider(
      remoteLoader: () async => <String, dynamic>{},
      remoteUpdater: (_) async {},
    );
    await preferences.bindUser('quick-settings-dismiss-user');
    addTearDown(preferences.dispose);
    final themeMode = ThemeModeProvider();
    addTearDown(themeMode.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: preferences),
          ChangeNotifierProvider.value(value: themeMode),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.white)),
                Align(
                  alignment: Alignment.bottomRight,
                  child: HexoraQuickSettingsButton(
                    headerPosition: GlobalHeaderPosition.bottom,
                    onOpenAllPreferences: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('quick-settings-button'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-settings-panel')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-settings-panel')), findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-settings-panel')), findsNothing);
  });
}
