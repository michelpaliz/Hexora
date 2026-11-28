import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/chat_sidebar_menu.dart';

void main() {
  testWidgets('creation menu exposes only authorized actions', (tester) async {
    var created = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 250,
          child: ChatSidebarMenu(
            collapsed: false,
            onMembers: () {},
            onCreateIssue: () => created = true,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('New conversation'));
    await tester.pumpAndSettle();
    expect(find.text('New team chat'), findsNothing);
    await tester.tap(find.text('New incident'));
    await tester.pumpAndSettle();
    expect(created, isTrue);
  });

  testWidgets('restricted icon-only menu still opens members', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 72,
          child: ChatSidebarMenu(
            collapsed: true,
            onMembers: () => opened = true,
          ),
        ),
      ),
    ));
    expect(find.byIcon(Icons.add), findsNothing);
    await tester.tap(find.byIcon(Icons.people_outline));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
