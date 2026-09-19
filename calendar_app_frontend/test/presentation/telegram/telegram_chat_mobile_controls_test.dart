import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/telegram/telegram.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_chat_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.android),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('phone chat header has one action menu and a back control',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var backs = 0;
    var exports = 0;

    await tester.pumpWidget(_app(WorkspaceHeader(
      chat: const TelegramChat(
        id: 'chat',
        title: 'Empresa Michel S.L',
        type: 'group',
      ),
      selectedTopic: null,
      topics: const [],
      tabController: null,
      isLoadingTopics: false,
      topicError: null,
      onRefresh: () {},
      onExportChat: () => exports++,
      showMobileBack: true,
      onMobileBack: () => backs++,
    )));

    expect(tester.takeException(), isNull);
    expect(find.text('Empresa Michel S.L'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(exports, 1);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backs, 1);
  });

  testWidgets('forum header and topics fit a narrow phone with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const general = TelegramForumTopic(
      forumTopicId: 'general',
      chatId: 'chat',
      name: 'General',
      isGeneral: true,
    );
    const hours = TelegramForumTopic(
      forumTopicId: 'hours',
      chatId: 'chat',
      name: 'Horas_Trabajadores',
    );
    await tester.pumpWidget(_app(DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: WorkspaceHeader(
            chat: const TelegramChat(
              id: 'chat',
              title: 'Empresa Michel S.L',
              type: 'supergroup',
              forum: TelegramChatForumInfo(isForum: true),
            ),
            selectedTopic: general,
            topics: const [general, hours],
            tabController: DefaultTabController.of(context),
            isLoadingTopics: false,
            topicError: null,
            onRefresh: () {},
            onExportChat: () {},
            showMobileBack: true,
            onMobileBack: () {},
          ),
        ),
      ),
    )));

    expect(find.text('Empresa Michel S.L'), findsOneWidget);
    expect(find.text('Horas_Trabajadores'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone composer groups attachments and keeps send accessible',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    var workerPdfs = 0;
    var sends = 0;

    await tester.pumpWidget(_app(AnimatedBuilder(
      animation: controller,
      builder: (context, _) => TelegramChatComposer(
        controller: controller,
        focusNode: focusNode,
        enabled: true,
        isSending: false,
        error: null,
        replyTarget: null,
        attachment: null,
        onSend: () => sends++,
        onPickAttachment: () {},
        onPickClientDocument: () {},
        onPickWorkerDocument: () => workerPdfs++,
        onPickIssuedPresupuesto: () {},
        onClearAttachment: () {},
        onClearReply: () {},
        onKeyEvent: (_, KeyEvent event) => KeyEventResult.ignored,
      ),
    )));

    await tester.tap(find.byIcon(Icons.attach_file_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Local file'), findsOneWidget);
    expect(find.text('Client PDF'), findsOneWidget);
    expect(find.text('Worker-hours PDF'), findsOneWidget);
    await tester.tap(find.text('Worker-hours PDF'));
    await tester.pumpAndSettle();
    expect(workerPdfs, 1);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    expect(sends, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone message keeps reply reachable with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var replies = 0;

    await tester.pumpWidget(_app(Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: TelegramMessageItem(
          message: TelegramChatMessage(
            messageId: 'message',
            timestamp: DateTime.utc(2026, 9, 18, 13, 59),
            editTimestamp: DateTime.utc(2026, 9, 18, 14),
            sender: const TelegramChatMessageSender(
              displayName: 'Michael Paliz',
            ),
            messageType: 'text',
            text: 'A short message',
          ),
          onReplyRequested: () => replies++,
        ),
      ),
    )));

    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Reply'));
    expect(replies, 1);
  });

  testWidgets('PDF without a file link explains why preview is unavailable',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const TelegramMessageItem(
      message: TelegramChatMessage(
        messageId: 'document',
        messageType: 'document',
        media: TelegramChatMessageMedia(
          fileName: 'report.pdf',
          mimeType: 'application/pdf',
        ),
      ),
    )));

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.textContaining('Preview unavailable for this file'),
        findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
