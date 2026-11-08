import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab_bar.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

WorkspaceTab _tab(String id) => WorkspaceTab(
      identity: WorkspaceTabIdentity(id),
      section: id,
      title: id.toUpperCase(),
      icon: Icons.tab_outlined,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('openOrActivateTab prevents duplicate logical tabs', () {
    final manager = WorkspaceTabManager(businessId: 'business-1');

    manager.openOrActivateTab(_tab('bank'));
    manager.openOrActivateTab(_tab('expenses'));
    manager.openOrActivateTab(_tab('bank'));

    expect(manager.tabs.map((tab) => tab.identity.value), ['bank', 'expenses']);
    expect(manager.activeIdentity, const WorkspaceTabIdentity('bank'));
  });

  test('reopening a logical tab refreshes its navigation arguments', () {
    final manager = WorkspaceTabManager(businessId: 'business');
    const identity = WorkspaceTabIdentity('invoice:42');
    manager.openOrActivateTab(
      const WorkspaceTab(
        identity: identity,
        section: 'invoices',
        title: 'Invoice',
        icon: Icons.receipt_long_outlined,
        arguments: <String, String>{'initialMenu': 'invoices_drafts'},
      ),
    );

    manager.openOrActivateTab(
      const WorkspaceTab(
        identity: identity,
        section: 'invoices',
        title: 'Invoice',
        icon: Icons.receipt_long_outlined,
        arguments: <String, String>{
          'initialMenu': 'invoice_editor',
          'navigationRevision': '2',
        },
      ),
    );

    expect(manager.tabs, hasLength(1));
    expect(manager.activeTab?.arguments['initialMenu'], 'invoice_editor');
    expect(manager.activeTab?.arguments['navigationRevision'], '2');
  });

  test('closing the active tab restores the most recently used tab', () {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    manager.openOrActivateTab(_tab('bank'));
    manager.openOrActivateTab(_tab('expenses'));
    manager.openOrActivateTab(_tab('calendar'));
    manager.activateTab(const WorkspaceTabIdentity('bank'));

    manager.closeTab(const WorkspaceTabIdentity('bank'));

    expect(manager.activeIdentity, const WorkspaceTabIdentity('calendar'));
  });

  test('title updates do not change tab identity or create a duplicate', () {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    manager.openOrActivateTab(_tab('invoice:new'));

    manager.updateTabTitle(
      const WorkspaceTabIdentity('invoice:new'),
      'Invoice #2026-041',
    );

    expect(manager.tabs, hasLength(1));
    expect(manager.tabs.single.identity.value, 'invoice:new');
    expect(manager.tabs.single.title, 'Invoice #2026-041');
  });

  test('restoration is user and business scoped and deduplicated', () async {
    SharedPreferences.setMockInitialValues({
      'hexora.workspace_tabs.user-1.business-1': jsonEncode({
        'activeIdentity': 'bank',
        'tabs': [
          _tab('bank').toSnapshot().toJson(),
          _tab('bank').toSnapshot().toJson(),
          _tab('forbidden').toSnapshot().toJson(),
        ],
      }),
    });
    final manager = WorkspaceTabManager(businessId: 'business-1');
    await manager.configureSession('user-1');

    final restored = await manager.restore(
      resolver: (snapshot) =>
          snapshot.identity == 'forbidden' ? null : _tab(snapshot.identity),
    );

    expect(restored, isTrue);
    expect(manager.tabs, hasLength(1));
    expect(manager.activeIdentity, const WorkspaceTabIdentity('bank'));
  });

  testWidgets('inactive tab widgets keep their form state', (tester) async {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    manager.openOrActivateTab(_tab('invoice:new'));
    manager.openOrActivateTab(_tab('bank'));
    manager.activateTab(const WorkspaceTabIdentity('invoice:new'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceContent(
            manager: manager,
            builder: (_, tab) => TextField(
              key: ValueKey('field-${tab.identity.value}'),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-invoice:new')),
      'unsaved invoice draft',
    );

    manager.updateTabTitle(
      const WorkspaceTabIdentity('invoice:new'),
      'Invoice #2026-041',
    );
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'unsaved invoice draft',
    );

    manager.activateTab(const WorkspaceTabIdentity('bank'));
    await tester.pump();
    manager.activateTab(const WorkspaceTabIdentity('invoice:new'));
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, 'unsaved invoice draft');
  });

  testWidgets(
      'layout-sensitive workspace keeps a stable ancestor chain on tab switch',
      (tester) async {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    manager.openOrActivateTab(_tab('proposals'));
    manager.openOrActivateTab(_tab('bank'));
    manager.activateTab(const WorkspaceTabIdentity('proposals'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceContent(
            manager: manager,
            builder: (_, tab) => Row(
              children: [
                const SizedBox(width: 248),
                Expanded(
                  child: WorkspaceMainContent(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Column(
                        children: [
                          TextField(
                            key: ValueKey(
                              'layout-field-${tab.identity.value}',
                            ),
                          ),
                          MenuAnchor(
                            menuChildren: const [
                              MenuItemButton(child: Text('Menu item')),
                            ],
                            builder: (context, controller, _) => TextButton(
                              onPressed: controller.open,
                              child: const Text('Open menu'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('layout-field-proposals')),
      'proposal draft state',
    );

    manager.activateTab(const WorkspaceTabIdentity('bank'));
    await tester.pump();
    manager.activateTab(const WorkspaceTabIdentity('proposals'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(WorkspaceTabBar), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'proposal draft state',
    );
  });

  testWidgets('closing the active tab keeps the surviving workspace mounted',
      (tester) async {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    manager.openOrActivateTab(_tab('bank'));
    manager.openOrActivateTab(_tab('proposals'));
    manager.activateTab(const WorkspaceTabIdentity('bank'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceContent(
            manager: manager,
            builder: (_, tab) => Row(
              children: [
                const SizedBox(width: 248),
                Expanded(
                  child: WorkspaceMainContent(
                    child: TextField(
                      key: ValueKey('close-field-${tab.identity.value}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('close-field-bank')),
      'bank workspace state',
    );
    manager.activateTab(const WorkspaceTabIdentity('proposals'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(manager.activeIdentity, const WorkspaceTabIdentity('bank'));
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'bank workspace state',
    );
  });

  testWidgets('dirty tabs ask before closing', (tester) async {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    final tab = _tab('invoice:new');
    manager.openOrActivateTab(tab);
    manager.setDirty(tab.identity, dirty: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceContent(
            manager: manager,
            builder: (_, tab) => WorkspaceMainContent(child: Text(tab.title)),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(manager.tabs, hasLength(1));
  });

  testWidgets('tab strip follows the right edge of the module sidebar',
      (tester) async {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    manager.openOrActivateTab(_tab('bank'));
    final sidebarWidth = ValueNotifier<double>(248);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<double>(
            valueListenable: sidebarWidth,
            builder: (_, width, __) => WorkspaceContent(
              manager: manager,
              builder: (_, tab) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const ValueKey('module-sidebar'),
                    width: width,
                    child: const ColoredBox(color: Colors.blueGrey),
                  ),
                  Expanded(
                    child: WorkspaceMainContent(
                      child: ColoredBox(
                        key: const ValueKey('main-content'),
                        color: Colors.white,
                        child: Text(tab.title),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(WorkspaceTabBar)).dx,
      tester.getTopRight(find.byKey(const ValueKey('module-sidebar'))).dx,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('module-sidebar'))).dy,
      tester.getTopLeft(find.byType(WorkspaceTabBar)).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('main-content'))).dy,
      tester.getBottomLeft(find.byType(WorkspaceTabBar)).dy,
    );

    sidebarWidth.value = 56;
    await tester.pump();
    expect(
      tester.getTopLeft(find.byType(WorkspaceTabBar)).dx,
      tester.getTopRight(find.byKey(const ValueKey('module-sidebar'))).dx,
    );
  });

  testWidgets('overflowing workspace tabs show scrolling controls',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final manager = WorkspaceTabManager(businessId: 'business-1');
    for (var index = 0; index < 15; index++) {
      manager.openOrActivateTab(_tab('tab-$index'));
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceContent(
            manager: manager,
            builder: (_, tab) => WorkspaceMainContent(child: Text(tab.title)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final left = find.byKey(const ValueKey('workspace-tab-scroll-left'));
    final right = find.byKey(const ValueKey('workspace-tab-scroll-right'));
    final leftButton =
        find.descendant(of: left, matching: find.byType(IconButton));
    final rightButton =
        find.descendant(of: right, matching: find.byType(IconButton));
    expect(left, findsOneWidget);
    expect(right, findsOneWidget);
    expect(tester.widget<IconButton>(rightButton).onPressed, isNotNull);

    await tester.tap(right);
    await tester.pumpAndSettle();

    expect(tester.widget<IconButton>(leftButton).onPressed, isNotNull);
    expect(manager.activeIdentity, const WorkspaceTabIdentity('tab-14'));
  });

  testWidgets('all tabs switcher searches and activates an existing tab',
      (tester) async {
    final manager = WorkspaceTabManager(businessId: 'business-1');
    for (var index = 0; index < 10; index++) {
      manager.openOrActivateTab(_tab('tab-$index'));
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceContent(
            manager: manager,
            builder: (_, tab) => WorkspaceMainContent(child: Text(tab.title)),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('workspace-all-tabs-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open tabs'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'TAB-2');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('workspace-all-tabs-tab-2')),
      findsOneWidget,
    );
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(manager.activeIdentity, const WorkspaceTabIdentity('tab-2'));
    expect(find.text('Open tabs'), findsNothing);
    expect(manager.tabs, hasLength(10));

    await tester.tap(
      find.byKey(const ValueKey('workspace-all-tabs-button')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty);
  });
}
