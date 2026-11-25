import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/presentation/screens/settings/widgets/section_card.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_system_config_section.dart';
import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends ChangeNotifier implements AuthProvider {
  final imports = <bool>[];

  @override
  User? get currentUser => null;

  @override
  Future<bool> setAutoStatementImportEnabled(bool enabled) async {
    imports.add(enabled);
    return enabled;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  final auth = _Auth();
  final theme = ThemeModeProvider();
  final locale = LocaleProvider();
  final preferences = UserPreferencesProvider(
    remoteLoader: () async => <String, dynamic>{},
    remoteUpdater: (_) async {},
  );
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required double width,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  // The browser stays wide; only the workspace width changes.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final h = _Harness();
  await h.preferences.bindUser('settings-user');
  h.locale.setLocale(const Locale('es'));
  addTearDown(h.preferences.dispose);
  addTearDown(h.theme.dispose);
  addTearDown(h.locale.dispose);

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: h.auth),
      ChangeNotifierProvider.value(value: h.theme),
      ChangeNotifierProvider.value(value: h.locale),
      ChangeNotifierProvider.value(value: h.preferences),
    ],
    child: MaterialApp(
      theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: AppColors.workspaceCanvas,
        body: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const SingleChildScrollView(
                child: SettingsSystemConfigSection(),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return h;
}

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('new users receive the recommended personal defaults',
      (tester) async {
    final h = await _pump(tester, width: 1200);

    expect(h.preferences.navigationLayout, NavigationLayout.unified);
    expect(
      h.preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );
    expect(
      h.preferences.globalHeaderPosition,
      GlobalHeaderPosition.bottom,
    );
    expect(h.theme.mode, ThemeMode.light);
    expect(h.theme.lightVariant, LightThemeVariant.neutral);
    expect(h.locale.locale, const Locale('es'));
  });

  for (final brightness in Brightness.values) {
    testWidgets(
        'wide: two equal columns, cards and themes in a row '
        '($brightness)', (tester) async {
      await _pump(tester, width: 1200, brightness: brightness);
      final profile = tester.getRect(_key('settings-profile-card'));
      final left = tester.getRect(_key('settings-navigation-column'));
      final right = tester.getRect(_key('settings-preferences-column'));

      expect(profile.width, 1200);
      expect(left.top, right.top);
      expect(left.width, right.width);
      expect(right.left - left.right, 20);
      expect(left.height, isNot(right.height), reason: 'natural heights');

      expect(tester.getRect(_key('navigation-layout-split')).top,
          tester.getRect(_key('navigation-layout-unified')).top);
      expect(
        {
          for (final t in ['automatic', 'light', 'lightBlue', 'dark'])
            tester.getRect(_key('appearance-$t')).top
        },
        hasLength(1),
      );
      // The profile is the only container card left.
      expect(find.byType(SectionCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('medium: two columns, stacked cards, 2 x 2 themes',
      (tester) async {
    await _pump(tester, width: 740);
    expect(tester.getRect(_key('settings-navigation-column')).top,
        tester.getRect(_key('settings-preferences-column')).top);
    expect(tester.getRect(_key('navigation-layout-unified')).top,
        greaterThan(tester.getRect(_key('navigation-layout-split')).bottom));
    final auto = tester.getRect(_key('appearance-automatic'));
    final light = tester.getRect(_key('appearance-light'));
    final blue = tester.getRect(_key('appearance-lightBlue'));
    expect(light.top, auto.top);
    expect(blue.top, greaterThan(auto.bottom));
    expect(blue.size, auto.size);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 560.0]) {
    testWidgets('narrow ($width): single column without overflow',
        (tester) async {
      await _pump(tester, width: width);
      final left = tester.getRect(_key('settings-navigation-column'));
      final right = tester.getRect(_key('settings-preferences-column'));
      expect(left.width, width);
      expect(right.top, greaterThan(left.bottom));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every width from phone to desktop lays out without overflow',
      (tester) async {
    for (var width = 320.0; width <= 1240; width += 40) {
      await _pump(tester, width: width);
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('large text falls back to one column', (tester) async {
    await _pump(tester, width: 900, textScale: 1.6);
    expect(tester.getRect(_key('settings-preferences-column')).top,
        greaterThan(tester.getRect(_key('settings-navigation-column')).bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation preferences apply at once without moving the layout',
      (tester) async {
    final h = await _pump(tester, width: 1200);
    Map<String, Rect> rects() => {
          for (final k in [
            'navigation-layout-split',
            'navigation-layout-unified',
            'navigation-display-iconsOnly',
            'settings-preferences-column',
          ])
            k: tester.getRect(_key(k)),
        };
    final before = rects();
    await tester.tap(_key('navigation-layout-split'));
    await tester.pumpAndSettle();
    expect(h.preferences.navigationLayout, NavigationLayout.split);
    await tester.tap(_key('navigation-display-automatic'));
    await tester.pumpAndSettle();
    expect(
        h.preferences.navigationDisplayMode, NavigationDisplayMode.automatic);
    expect(rects(), before);

    BoxDecoration border(String k) => tester
        .widget<AnimatedContainer>(find.descendant(
            of: _key(k), matching: find.byType(AnimatedContainer)))
        .foregroundDecoration! as BoxDecoration;
    final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    expect((border('navigation-layout-split').border! as Border).top.color,
        cs.primary);
    expect((border('navigation-layout-unified').border! as Border).top.color,
        cs.outlineVariant);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the four themes keep their existing mode and variant',
      (tester) async {
    final h = await _pump(tester, width: 1200);
    for (final (key, mode, variant) in [
      ('dark', ThemeMode.dark, LightThemeVariant.neutral),
      ('lightBlue', ThemeMode.light, LightThemeVariant.blue),
      ('light', ThemeMode.light, LightThemeVariant.neutral),
      ('automatic', ThemeMode.system, LightThemeVariant.neutral),
    ]) {
      await tester.tap(_key('appearance-$key'));
      await tester.pumpAndSettle();
      expect(h.theme.mode, mode, reason: key);
      expect(h.theme.lightVariant, variant, reason: key);
    }
  });

  testWidgets('language, automatic import and security still work',
      (tester) async {
    final h = await _pump(tester, width: 1200);
    await tester.tap(_key('language-en'));
    await tester.pumpAndSettle();
    expect(h.locale.locale.languageCode, 'en');

    await tester.tap(_key('settings-auto-import'));
    await tester.pumpAndSettle();
    expect(h.auth.imports, [true]);

    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm-logout')), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
