import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user_model/user.dart';
import 'package:hexora/services/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/presentation/screens/settings/dialogs/logout_dialog.dart';
import 'package:hexora/presentation/screens/settings/dialogs/change_password_dialog.dart';
import 'package:hexora/presentation/screens/settings/dialogs/change_username_dialog.dart';
import 'package:hexora/presentation/screens/workspace/dashboard_screen/widgets/right_panel/settings_section/sections/settings_system_config_section.dart';
import 'package:hexora/presentation/screens/settings/screens/settings.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  User? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _typography = AppTypography(
  displayLarge: TextStyle(), displayMedium: TextStyle(),
  titleLarge: TextStyle(), bodyLarge: TextStyle(),
  bodyMedium: TextStyle(), bodySmall: TextStyle(),
  // Deliberately white: dialog labels must not inherit this override.
  buttonText: TextStyle(color: Colors.white), caption: TextStyle(),
  accentHeading: TextStyle(), accentText: TextStyle(),
);

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

Widget _app(ThemeData theme, Widget home) => MaterialApp(
      theme: theme.copyWith(
        textTheme: ThemeData(brightness: theme.brightness).textTheme,
        extensions: const [_typography],
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final brightness in Brightness.values) {
    testWidgets('logout dialog uses readable palette colors in $brightness',
        (tester) async {
      final theme = AppTheme.fromBrightness(brightness);
      bool? confirmed;
      await tester.pumpWidget(_app(
          theme,
          Scaffold(
              body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  confirmed = await showLogoutDialog(context),
              child: const Text('Open'),
            ),
          ))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final cs = theme.colorScheme;
      expect(
          tester.widget<AlertDialog>(find.byType(AlertDialog)).backgroundColor,
          cs.surface);
      final button = find.byKey(const ValueKey('confirm-logout'));
      final style = tester.widget<FilledButton>(button).style!;
      expect(style.backgroundColor!.resolve({}), cs.error);
      expect(style.foregroundColor!.resolve({}), cs.onError);
      final label =
          find.descendant(of: button, matching: find.byType(RichText));
      expect(tester.widget<RichText>(label).text.style!.color, cs.onError);
      expect(_contrast(cs.error, cs.onError), greaterThanOrEqualTo(4.5));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Settings shares primary icons and logout colors in $brightness',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = AppTheme.fromBrightness(brightness);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: _app(theme, const Settings()),
      ));
      await tester.pumpAndSettle();
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          theme.scaffoldBackgroundColor);
      for (final icon in [
        Icons.person_outline_rounded,
        Icons.lock_outline_rounded,
        Icons.light_mode_rounded,
        Icons.sync_rounded,
        Icons.language_rounded
      ]) {
        expect(tester.widget<Icon>(find.byIcon(icon)).color,
            theme.colorScheme.primary);
      }
      expect(tester.widget<Icon>(find.byIcon(Icons.logout_rounded)).color,
          theme.colorScheme.error);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('confirm-logout')), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(Settings), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: _app(
            theme,
            const Scaffold(
              body: SingleChildScrollView(child: SettingsSystemConfigSection()),
            )),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('confirm-logout')), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsSystemConfigSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'account dialog labels inherit palette button colors in $brightness',
        (tester) async {
      final theme = AppTheme.fromBrightness(brightness);
      await tester.pumpWidget(_app(
          theme,
          Scaffold(
              body: Builder(
            builder: (context) => Column(children: [
              TextButton(
                  onPressed: () => showChangeUsernameDialog(context),
                  child: const Text('Username')),
              TextButton(
                  onPressed: () => showChangePasswordDialog(context),
                  child: const Text('Password')),
            ]),
          ))));
      for (final label in ['Username', 'Password']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<AlertDialog>(find.byType(AlertDialog))
                .backgroundColor,
            theme.colorScheme.surface);
        final save = find.byType(ElevatedButton);
        final disabled = tester.widget<ElevatedButton>(save);
        expect(disabled.onPressed, isNull);
        expect(disabled.style!.backgroundColor!.resolve({WidgetState.disabled}),
            theme.colorScheme.onSurface.withValues(alpha: 0.12));
        final fields = find.byType(TextField);
        if (label == 'Username') {
          await tester.enterText(fields, 'tester_1');
        } else {
          await tester.enterText(fields.at(0), 'oldpass123');
          await tester.enterText(fields.at(1), 'newpass123');
          await tester.enterText(fields.at(2), 'newpass123');
        }
        await tester.pumpAndSettle();
        expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
        final text = find.descendant(of: save, matching: find.byType(RichText));
        expect(tester.widget<RichText>(text).text.style!.color,
            theme.colorScheme.onPrimary);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'shared button variants use paired palette colors in $brightness',
        (tester) async {
      final theme = AppTheme.fromBrightness(brightness);
      await tester.pumpWidget(_app(theme, const Scaffold(body: SizedBox())));
      final context = tester.element(find.byType(Scaffold));
      final cs = theme.colorScheme;
      for (final variant in ButtonVariant.values) {
        final style = ThemedButtons.button(context, variant: variant);
        final (background, foreground) = switch (variant) {
          ButtonVariant.primary => (cs.primary, cs.onPrimary),
          ButtonVariant.danger => (cs.error, cs.onError),
          _ => (cs.secondary, cs.onSecondary),
        };
        expect(style.backgroundColor!.resolve({}), background);
        expect(style.foregroundColor!.resolve({}), foreground);
        expect(_contrast(background, foreground), greaterThanOrEqualTo(4.5));
        expect(style.backgroundColor!.resolve({WidgetState.disabled}),
            cs.onSurface.withValues(alpha: 0.12));
        expect(style.foregroundColor!.resolve({WidgetState.disabled}),
            cs.onSurface.withValues(alpha: 0.38));
      }
    });
  }
}
