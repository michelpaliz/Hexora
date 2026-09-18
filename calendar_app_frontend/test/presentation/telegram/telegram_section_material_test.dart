import 'package:hexora/theme/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/telegram/telegram.dart';
import 'package:hexora/services/telegram/api/telegram_api_client.dart';
import 'package:hexora/services/telegram/domain/telegram_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/telegram_section_screen.dart';

class _UnusedApi implements ITelegramApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Domain extends TelegramDomain {
  _Domain() : super(apiClient: _UnusedApi());
  @override
  TelegramAccount get account =>
      const TelegramAccount(id: 'test', status: 'active', firstName: 'Michael');
  @override
  bool get isConnected => true;
  @override
  Future<void> loadAccount({bool force = false}) async {}
  @override
  Future<void> loadChats({bool refresh = false}) async {}
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Mobile Telegram without host Material in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final domain = _Domain();
      addTearDown(domain.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<TelegramDomain>.value(
        value: domain,
        child: MaterialApp(
          theme: AppTheme.forPlatform(brightness,
              platform: TargetPlatform.android),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TelegramSectionScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Chats'), findsWidgets);
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Account'),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Michael'), findsWidgets);
      expect(find.text('Disconnect'), findsOneWidget);
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(find.text('Disconnect Telegram?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Chats'),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Mobile Telegram navigation fits a narrow Spanish layout',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final domain = _Domain();
    addTearDown(domain.dispose);

    await tester.pumpWidget(ChangeNotifierProvider<TelegramDomain>.value(
      value: domain,
      child: MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        locale: const Locale('es'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TelegramSectionScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Exportaciones'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Cuenta'),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Desconectar'), findsOneWidget);
  });
}
