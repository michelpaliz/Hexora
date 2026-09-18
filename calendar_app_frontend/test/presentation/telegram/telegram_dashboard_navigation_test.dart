import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/telegram/telegram.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/navigation/dashboard_sections.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_actions.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_state.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/services/telegram/api/telegram_api_client.dart';
import 'package:hexora/services/telegram/domain/telegram_domain.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _UnusedApi implements ITelegramApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TelegramDomain extends TelegramDomain {
  _TelegramDomain({this.forum = false}) : super(apiClient: _UnusedApi());

  final bool forum;

  static const _chat = TelegramChat(
    id: 'chat',
    title: 'Test chat',
    type: 'group',
  );
  static const _forumChat = TelegramChat(
    id: 'chat',
    title: 'Test forum',
    type: 'supergroup',
    forum: TelegramChatForumInfo(isForum: true),
  );

  TelegramChat get _selectedChat => forum ? _forumChat : _chat;

  @override
  TelegramAccount get account =>
      const TelegramAccount(id: 'account', status: 'active');

  @override
  bool get isConnected => true;

  @override
  List<TelegramChat> get chats => [_selectedChat];

  @override
  TelegramChat? get selectedChat =>
      selectedChatId == null ? null : _selectedChat;

  @override
  Future<void> loadAccount({bool force = false}) async {}

  @override
  Future<void> loadChats({bool refresh = false}) async {}

  @override
  Future<void> openChat(String chatId, {bool forceMessages = false}) async {
    selectChat(chatId);
  }
}

class _NarrowDashboardState implements GroupDashboardState {
  _NarrowDashboardState(this.context);

  @override
  final BuildContext context;

  @override
  bool get isWide => false;

  @override
  bool get canSeeAdmin => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final forum in [false, true]) {
    testWidgets(
        'Telegram ${forum ? 'forum' : 'chat'} has one back button on mobile',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final domain = _TelegramDomain(forum: forum);
      addTearDown(domain.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<TelegramDomain>.value(
          value: domain,
          child: MaterialApp(
            theme: AppTheme.forPlatform(
              Brightness.light,
              platform: TargetPlatform.android,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => DashboardActions.openSection(
                      _NarrowDashboardState(context),
                      Sections.telegram,
                    ),
                    child: const Text('Open Telegram'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Telegram'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TelegramSectionScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      domain.selectChat('chat');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TelegramSectionScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      domain.selectChat('chat');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  }
}
