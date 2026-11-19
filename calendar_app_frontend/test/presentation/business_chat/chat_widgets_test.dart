import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/chat_user_avatar.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/compact_chat_bubble.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/chat_message_actions.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/chat_composer.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/channel_avatar.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/mobile_chat_inbox_header.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/compact_conversation_tile.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('ChatUserAvatar shows initials when no photo is available',
      (tester) async {
    await tester.pumpWidget(_host(
      const ChatUserAvatar(name: 'Ada Lovelace', size: 30),
    ));
    expect(find.text('AL'), findsOneWidget);
  });

  testWidgets('short message produces a short, max-width-bounded bubble',
      (tester) async {
    await tester.pumpWidget(_host(
      const CompactChatBubble(
        mine: false,
        isFirstInGroup: true,
        isLastInGroup: true,
        maxWidth: 520,
        child: Text('Hi'),
      ),
    ));
    final size = tester.getSize(find.byType(CompactChatBubble));
    // Content-sized: a two-letter message must not stretch anywhere near the
    // maximum bubble width.
    expect(size.width, lessThan(200));
    expect(size.width, lessThanOrEqualTo(520));
  });

  testWidgets('message actions render in a floating toolbar, not inline',
      (tester) async {
    var replied = false;
    await tester.pumpWidget(_host(
      ChatMessageActions(
        mine: false,
        actions: [
          ChatMessageAction(
            icon: Icons.reply_rounded,
            label: 'Reply',
            onSelected: () => replied = true,
          ),
        ],
        child: const SizedBox(width: 120, height: 40, child: Text('body')),
      ),
    ));

    // The action lives in a contextual toolbar overlaying the bubble rather
    // than a permanently reserved inline icon; invoking it runs the callback.
    final replyButton = find.widgetWithIcon(IconButton, Icons.reply_rounded);
    expect(replyButton, findsOneWidget);
    expect(find.ancestor(of: replyButton, matching: find.byType(Stack)),
        findsWidgets);
    tester.widget<IconButton>(replyButton).onPressed!();
    expect(replied, isTrue);
  });

  testWidgets('composer send button is gated on non-empty text',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var sent = 0;
    var plus = 0;
    await tester.pumpWidget(_host(
      ChatComposer(
        controller: controller,
        enabled: true,
        sending: false,
        narrow: false,
        onSend: () => sent++,
        onPlus: () => plus++,
        hintText: 'Write a message…',
        sendTooltip: 'Send',
        plusTooltip: 'Add',
      ),
    ));

    final sendButton = find.widgetWithIcon(IconButton, Icons.send_rounded);
    expect(tester.widget<IconButton>(sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    expect(tester.widget<IconButton>(sendButton).onPressed, isNotNull);

    await tester.tap(sendButton);
    await tester.pump();
    expect(sent, 1);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add_rounded));
    await tester.pump();
    expect(plus, 1);
  });

  testWidgets('mobile inbox tile uses a circular channel avatar',
      (tester) async {
    await tester.pumpWidget(_host(
      const SizedBox(
        width: 360,
        child: CompactConversationTile(
          icon: Icons.campaign_outlined,
          title: 'General',
          preview: 'Welcome',
          circularAvatar: true,
        ),
      ),
    ));
    final avatar = tester.widget<ChannelAvatar>(find.byType(ChannelAvatar));
    expect(avatar.circular, isTrue);
    final decoration = tester
        .widget<Container>(find.descendant(
            of: find.byType(ChannelAvatar), matching: find.byType(Container)))
        .decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
  });

  testWidgets('mobile inbox header is a single compact bar with one back action',
      (tester) async {
    var backed = 0;
    await tester.pumpWidget(_host(
      MobileChatInboxHeader(
        title: 'Hexora Chat',
        connected: true,
        statusLabel: 'Connected',
        unreadTotal: 3,
        onBack: () => backed++,
        trailing: const [Icon(Icons.people_alt_outlined)],
      ),
    ));
    expect(tester.getSize(find.byType(MobileChatInboxHeader)).height, 60);
    expect(find.text('Hexora Chat'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backed, 1);
  });
}
