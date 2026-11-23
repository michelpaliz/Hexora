import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/telegram/telegram.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_chat_list.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_chat_view.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/services/telegram/api/telegram_api_client.dart';
import 'package:hexora/services/telegram/domain/telegram_domain.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

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

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

TelegramChatMessage _msg(
  String id, {
  String senderId = '42',
  String name = 'Ana López',
  String type = 'user',
  DateTime? at,
  String text = 'Hola, os envío el parte de horas.',
  TelegramChatMessageForwardInfo? forward,
}) =>
    TelegramChatMessage(
      messageId: id,
      timestamp: at ?? DateTime(2026, 11, 23, 10, 0),
      sender: TelegramChatMessageSender(
        id: senderId,
        type: type,
        displayName: name,
      ),
      text: text,
      messageType: 'text',
      forwardInfo: forward,
    );

BoxDecoration _decoration(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  final decoration = widget is AnimatedContainer
      ? widget.decoration
      : (widget as Container).decoration;
  return decoration! as BoxDecoration;
}

void main() {
  group('sender identity and grouping', () {
    test('outgoing only when the Telegram sender id is the account user', () {
      expect(telegramIsOwnMessage(_msg('1', senderId: '42'), '42'), isTrue);
      expect(telegramIsOwnMessage(_msg('1', senderId: 'user42'), '42'), isTrue);
      expect(telegramIsOwnMessage(_msg('1', senderId: '43'), '42'), isFalse);
      expect(telegramIsOwnMessage(_msg('1', senderId: '42'), null), isFalse,
          reason: 'unknown account id never guesses');
      expect(
        telegramIsOwnMessage(_msg('1', senderId: '42', type: 'chat'), '42'),
        isFalse,
        reason: 'messages posted as the chat/channel are not "mine"',
      );
    });

    test('runs: same sender within 5 minutes, never across forwards', () {
      final first = _msg('1');
      expect(
        telegramMessagesShareRun(
            first, _msg('2', at: DateTime(2026, 11, 23, 10, 3))),
        isTrue,
      );
      expect(
        telegramMessagesShareRun(
            first, _msg('2', at: DateTime(2026, 11, 23, 10, 6))),
        isFalse,
      );
      expect(
        telegramMessagesShareRun(first, _msg('2', senderId: '7', name: 'Luis')),
        isFalse,
      );
      expect(
        telegramMessagesShareRun(
          first,
          _msg('2',
              forward: const TelegramChatMessageForwardInfo(sourceName: 'X')),
        ),
        isFalse,
      );
    });
  });

  group('message bubbles', () {
    for (final brightness in Brightness.values) {
      testWidgets('incoming bubble is white with avatar and name ($brightness)',
          (tester) async {
        await _size(tester, const Size(1000, 700));
        await tester.pumpWidget(_app(
          TelegramMessageItem(message: _msg('1'), onReplyRequested: () {}),
          brightness: brightness,
        ));
        final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
        expect(
          _decoration(
                  tester, find.byKey(const ValueKey('telegram-message-bubble')))
              .color,
          cs.surface,
        );
        expect(find.byKey(const ValueKey('telegram-message-avatar')),
            findsOneWidget);
        expect(find.text('Ana López'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('follow-up in a run hides avatar/name, keeps time and reply',
        (tester) async {
      await _size(tester, const Size(1000, 700));
      var replies = 0;
      await tester.pumpWidget(_app(TelegramMessageItem(
        message: _msg('2', at: DateTime(2026, 11, 23, 10, 2)),
        showSender: false,
        onReplyRequested: () => replies++,
      )));
      expect(
          find.byKey(const ValueKey('telegram-message-avatar')), findsNothing);
      expect(find.text('Ana López'), findsNothing);
      expect(find.text('10:02'), findsOneWidget);
      await tester.tap(find.byTooltip('Responder'));
      expect(replies, 1);
    });

    testWidgets('outgoing bubble is pale blue, right-aligned, no avatar',
        (tester) async {
      await _size(tester, const Size(1000, 700));
      await tester.pumpWidget(_app(TelegramMessageItem(
        message: _msg('3', text: 'Recibido'),
        isOutgoing: true,
      )));
      final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      final bubble = find.byKey(const ValueKey('telegram-message-bubble'));
      final color = _decoration(tester, bubble).color!;
      expect(color, isNot(cs.surface));
      expect(color.b, greaterThan(color.r), reason: 'blue tint');
      expect(tester.getRect(bubble).right, closeTo(1000, 1));
      expect(tester.getRect(bubble).left, greaterThan(500));
      expect(
          find.byKey(const ValueKey('telegram-message-avatar')), findsNothing);
    });

    testWidgets('long messages stay within ~82% of the canvas', (tester) async {
      await _size(tester, const Size(1000, 700));
      await tester.pumpWidget(_app(TelegramMessageItem(
        message: _msg('4', text: List.filled(80, 'palabra').join(' ')),
      )));
      final bubble =
          tester.getRect(find.byKey(const ValueKey('telegram-message-bubble')));
      expect(bubble.width, lessThanOrEqualTo(1000 * .82));
      expect(tester.takeException(), isNull);
    });
  });

  group('conversation list', () {
    const chats = [
      TelegramChat(id: 'a', title: 'Empresa Michel S.L', type: 'supergroup'),
      TelegramChat(id: 'b', title: 'Belman', type: 'private'),
    ];

    for (final brightness in Brightness.values) {
      testWidgets('selected row is white with a blue indicator ($brightness)',
          (tester) async {
        await _size(tester, const Size(360, 600));
        await tester.pumpWidget(_app(
          SizedBox(
            width: 320,
            child: TelegramChatListWidget(
              chats: chats,
              selectedChatId: 'a',
              isLoading: false,
              error: null,
              onRefresh: () {},
              onChatTap: (_) {},
            ),
          ),
          brightness: brightness,
        ));
        final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
        Finder part(String id, Finder matching) => find
            .descendant(
              of: find.byKey(ValueKey('telegram-chat-row-$id')),
              matching: matching,
            )
            .first;

        expect(
            _decoration(tester, part('a', find.byType(AnimatedContainer)))
                .color,
            cs.surface);
        expect(
            _decoration(tester, part('b', find.byType(AnimatedContainer)))
                .color,
            Colors.transparent);
        expect(
          _decoration(
                  tester,
                  part(
                      'a',
                      find.byKey(
                          const ValueKey('telegram-chat-row-indicator'))))
              .color,
          cs.primary,
        );
        expect(
          tester
              .widget<Text>(find.text('Empresa Michel S.L'))
              .style!
              .fontWeight,
          FontWeight.w600,
        );
        expect(tester.widget<Text>(find.text('Belman')).style!.fontWeight,
            FontWeight.w500);
        expect(find.byType(Divider), findsNothing,
            reason: 'rows sit on the canvas without separators');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('selection does not move or resize the row', (tester) async {
      await _size(tester, const Size(360, 600));
      Widget list(String? selected) => _app(SizedBox(
            width: 320,
            child: TelegramChatListWidget(
              chats: chats,
              selectedChatId: selected,
              isLoading: false,
              error: null,
              onRefresh: () {},
              onChatTap: (_) {},
            ),
          ));
      await tester.pumpWidget(list(null));
      final before =
          tester.getRect(find.byKey(const ValueKey('telegram-chat-row-b')));
      await tester.pumpWidget(list('b'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const ValueKey('telegram-chat-row-b'))),
          before);
    });
  });

  group('desktop composer', () {
    Widget composer(TextEditingController controller, FocusNode focus) =>
        TelegramChatComposer(
          controller: controller,
          focusNode: focus,
          enabled: true,
          isSending: false,
          error: null,
          replyTarget: null,
          attachments: const [],
          onSend: () {},
          onPickAttachment: () {},
          onPickClientDocument: () {},
          onPickWorkerDocument: () {},
          onPickIssuedPresupuesto: () {},
          onRemoveAttachment: (_) {},
          onClearReply: () {},
          onKeyEvent: (_, __) => KeyEventResult.ignored,
        );

    testWidgets('one white surface, disabled send when empty, grows to ~140',
        (tester) async {
      await _size(tester, const Size(1000, 700));
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(_app(Align(
          alignment: Alignment.bottomCenter,
          child: composer(controller, focus))));

      final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      final surface = find.byKey(const ValueKey('telegram-composer-surface'));
      final deco = _decoration(tester, surface);
      expect(deco.color, cs.surface);
      expect(deco.borderRadius, BorderRadius.circular(12));
      final height = tester.getSize(surface).height;
      expect(height, inInclusiveRange(44, 56));
      expect(find.text('Escribe un mensaje…'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.send_rounded))
            .onPressed,
        isNull,
      );

      await tester.enterText(
          find.byKey(const ValueKey('telegram-composer-input')),
          List.filled(20, 'línea').join('\n'));
      await tester.pumpWidget(_app(Align(
          alignment: Alignment.bottomCenter,
          child: composer(controller, focus))));
      expect(
        tester
            .getSize(find.byKey(const ValueKey('telegram-composer-input')))
            .height,
        lessThanOrEqualTo(140),
      );
      expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.send_rounded))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('desktop chats sit on the canvas: no white parent surfaces',
      (tester) async {
    await _size(tester, const Size(1600, 900));
    final domain = _Domain();
    addTearDown(domain.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<TelegramDomain>.value(
      value: domain,
      child: MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.windows),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TelegramSectionScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<FolderPanel>(find.byType(FolderPanel)).backgroundColor,
        Colors.transparent);
    expect(
      _decoration(
              tester, find.byKey(const ValueKey('telegram-workspace-shell')))
          .color,
      Colors.transparent,
    );
    expect(tester.widget(find.byKey(const ValueKey('telegram-chats-sidebar'))),
        isA<Padding>());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
