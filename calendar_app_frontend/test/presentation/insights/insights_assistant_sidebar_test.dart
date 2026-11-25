import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_enums.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/widgets/insights_assistant_sidebar.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';

void main() {
  testWidgets('exposes conversation, configuration, and help actions',
      (tester) async {
    var newConversation = 0;
    var history = 0;
    var selectedMode = InsightsResponseMode.auto;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsAssistantSidebar(
            isSpanish: true,
            collapsed: false,
            days: 90,
            mode: InsightsResponseMode.auto,
            sending: false,
            onToggleCollapsed: () {},
            onNewConversation: () => newConversation++,
            onCurrentConversation: () {},
            onHistory: () => history++,
            onResetConversation: () {},
            onContext: () {},
            onModeChanged: (mode) => selectedMode = mode,
            onVisitGuide: () {},
            onInformation: () {},
          ),
        ),
      ),
    );

    final sidebar = tester.widget<CollapsibleSidebar>(
      find.byType(CollapsibleSidebar),
    );
    expect(sidebar.primaryAction?.label, 'Nueva conversación');
    expect(sidebar.groups.map((group) => group.label), [
      'CONVERSACIÓN',
      'CONFIGURACIÓN',
      'AYUDA',
    ]);

    final contextItem = sidebar.groups[1].items.first;
    expect(contextItem.label, 'Contexto');
    expect((contextItem.trailing! as Text).data, '90d');
    expect(sidebar.groups[1].items[1].selected, isTrue);
    expect(sidebar.groups[1].items[2].selected, isFalse);

    sidebar.primaryAction!.onTap!();
    sidebar.groups[0].items[1].onTap!();
    sidebar.groups[1].items[2].onTap!();
    expect(newConversation, 1);
    expect(history, 1);
    expect(selectedMode, InsightsResponseMode.stream);
  });

  testWidgets('disables destructive conversation actions while responding',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsAssistantSidebar(
            isSpanish: false,
            collapsed: true,
            days: 30,
            mode: InsightsResponseMode.stream,
            sending: true,
            onToggleCollapsed: () {},
            onNewConversation: () {},
            onCurrentConversation: () {},
            onHistory: () {},
            onResetConversation: () {},
            onContext: () {},
            onModeChanged: (_) {},
            onVisitGuide: () {},
            onInformation: () {},
          ),
        ),
      ),
    );

    final sidebar = tester.widget<CollapsibleSidebar>(
      find.byType(CollapsibleSidebar),
    );
    expect(sidebar.primaryAction?.onTap, isNull);
    expect(sidebar.groups[0].items[2].onTap, isNull);
    expect(sidebar.groups[1].items[2].selected, isTrue);
  });

  testWidgets('module selector stays in the assistant sidebar only',
      (tester) async {
    Widget assistant() => InsightsAssistantSidebar(
          isSpanish: true,
          collapsed: true,
          days: 90,
          mode: InsightsResponseMode.auto,
          sending: false,
          onToggleCollapsed: () {},
          onNewConversation: () {},
          onCurrentConversation: () {},
          onHistory: () {},
          onResetConversation: () {},
          onContext: () {},
          onModeChanged: (_) {},
          onVisitGuide: () {},
          onInformation: () {},
        );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SidebarHeaderScope(
            builder: (_, __) => const SizedBox(
              key: ValueKey('ai-module-grid-selector'),
              height: 44,
              child: Icon(Icons.grid_view_rounded),
            ),
            child: Row(
              children: [
                assistant(),
                Expanded(
                  child: SidebarHeaderScope(
                    enabled: false,
                    builder: (_, __) => const SizedBox.shrink(),
                    child: SidebarEdgeShell(
                      collapsed: false,
                      onToggle: () {},
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ai-module-grid-selector')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
