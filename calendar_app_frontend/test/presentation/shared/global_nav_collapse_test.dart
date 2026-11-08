import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/navigation/shell/hexora_app_shell.dart';
import 'package:hexora/navigation/shell/hexora_global_nav_bar.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab_bar.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab_manager.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

void main() {
  testWidgets('HEXORA toggles the global navigation without resetting state',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var collapsed = false;
    var activeId = 'income';
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return HexoraAppShell(
                  globalNavigationCollapsed: collapsed,
                  onRestoreGlobalNavigation: () =>
                      setState(() => collapsed = false),
                  globalNav: HexoraGlobalNavBar(
                    destinations: const [
                      HexoraNavDestination(
                        id: 'income',
                        icon: Icons.receipt_long_outlined,
                        label: 'Income',
                      ),
                      HexoraNavDestination(
                        id: 'expenses',
                        icon: Icons.trending_down_rounded,
                        label: 'Expenses',
                      ),
                    ],
                    activeId: activeId,
                    onSelected: (value) => setState(() => activeId = value),
                    groupSwitcher: const Text('Workspace'),
                    collapsed: collapsed,
                    onToggleCollapsed: () =>
                        setState(() => collapsed = !collapsed),
                  ),
                  body: const TextField(
                    key: ValueKey('persistent-workspace-field'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('global-nav-surface'))).height,
      NavigationTokens.globalBarHeight,
    );
    expect(find.text('Income').hitTestable(), findsOneWidget);
    expect(find.text('Workspace').hitTestable(), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('persistent-workspace-field')),
      'unsaved workspace state',
    );

    await tester.tap(find.text('HEXORA').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final viewport = find.byKey(
      const ValueKey('global-navigation-viewport'),
    );
    expect(tester.getSize(viewport).height, inExclusiveRange(0, 56));
    // The fixed navigation surface is clipped by the shell; its controls are
    // never laid out at the intermediate viewport height.
    expect(
      tester.getSize(find.byKey(const ValueKey('global-nav-surface'))).height,
      NavigationTokens.globalBarHeight,
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(viewport).height,
      0,
    );
    expect(find.text('Income').hitTestable(), findsNothing);
    expect(find.text('Workspace').hitTestable(), findsNothing);
    expect(find.text('HEXORA').hitTestable(), findsNothing);

    rebuild(() => collapsed = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(viewport).height, inExclusiveRange(0, 56));
    expect(
      tester.getSize(find.byKey(const ValueKey('global-nav-surface'))).height,
      NavigationTokens.globalBarHeight,
    );
    await tester.pumpAndSettle();

    expect(find.text('Income').hitTestable(), findsOneWidget);
    expect(activeId, 'income');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'unsaved workspace state',
    );
  });

  testWidgets(
      'collapsed navigation shares a row with tabs and restores from sidebar',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final manager = WorkspaceTabManager(businessId: 'business-1')
      ..openOrActivateTab(
        const WorkspaceTab(
          identity: WorkspaceTabIdentity('income'),
          title: 'Income',
          icon: Icons.receipt_long_outlined,
          section: 'income',
        ),
      );
    var collapsed = true;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return HexoraAppShell(
                globalNavigationCollapsed: collapsed,
                onRestoreGlobalNavigation: () =>
                    setState(() => collapsed = false),
                globalNav: HexoraGlobalNavBar(
                  destinations: const [
                    HexoraNavDestination(
                      id: 'income',
                      icon: Icons.receipt_long_outlined,
                      label: 'Income',
                    ),
                  ],
                  activeId: 'income',
                  onSelected: (_) {},
                  collapsed: collapsed,
                  onToggleCollapsed: () =>
                      setState(() => collapsed = !collapsed),
                ),
                body: WorkspaceContent(
                  manager: manager,
                  builder: (_, tab) => Row(
                    children: [
                      SizedBox(
                        key: const ValueKey('module-sidebar'),
                        width: NavigationTokens.sidebarWidth,
                        child: SidebarEdgeShell(
                          collapsed: false,
                          onToggle: () {},
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Expanded(
                        child: WorkspaceMainContent(child: Text(tab.title)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final header = find.byKey(
      const ValueKey('global-navigation-restore-header'),
    );
    expect(header, findsOneWidget);
    expect(tester.getSize(header).width, NavigationTokens.sidebarWidth);
    expect(tester.getTopLeft(find.byType(WorkspaceTabBar)).dy, 0);
    expect(
      tester.getTopLeft(find.byType(WorkspaceTabBar)).dx,
      NavigationTokens.sidebarWidth,
    );

    await tester.tap(header);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final viewport = find.byKey(
      const ValueKey('global-navigation-viewport'),
    );
    expect(tester.getSize(viewport).height, inExclusiveRange(0, 56));
    expect(
      tester.getSize(find.byKey(const ValueKey('global-nav-surface'))).height,
      NavigationTokens.globalBarHeight,
    );
    expect(header.hitTestable(), findsNothing);
    expect(
      tester.getTopLeft(find.byType(WorkspaceTabBar)).dy,
      tester.getSize(viewport).height,
    );
    await tester.pumpAndSettle();

    expect(header, findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('global-nav-surface'))).height,
      NavigationTokens.globalBarHeight,
    );

    // A rapid reverse continues from the current geometry without mounting a
    // second header or briefly squeezing the full navigation row.
    await tester.tap(find.text('HEXORA').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(tester.getSize(viewport).height, inExclusiveRange(0, 56));
    expect(
      tester.getSize(find.byKey(const ValueKey('global-nav-surface'))).height,
      NavigationTokens.globalBarHeight,
    );
    expect(header.hitTestable(), findsNothing);
    expect(
      tester.getTopLeft(find.byType(WorkspaceTabBar)).dy,
      tester.getSize(viewport).height,
    );
    rebuild(() => collapsed = false);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.getSize(viewport).height, NavigationTokens.globalBarHeight);
    expect(header, findsNothing);
  });

  testWidgets('reduced motion applies shell geometry immediately',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var collapsed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(1440, 900),
              disableAnimations: true,
            ),
            child: StatefulBuilder(
              builder: (context, setState) => HexoraAppShell(
                globalNavigationCollapsed: collapsed,
                onRestoreGlobalNavigation: () =>
                    setState(() => collapsed = false),
                globalNav: HexoraGlobalNavBar(
                  destinations: const [
                    HexoraNavDestination(
                      id: 'income',
                      icon: Icons.receipt_long_outlined,
                      label: 'Income',
                    ),
                  ],
                  activeId: 'income',
                  onSelected: (_) {},
                  collapsed: collapsed,
                  onToggleCollapsed: () =>
                      setState(() => collapsed = !collapsed),
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('HEXORA').hitTestable());
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('global-navigation-viewport')),
          )
          .height,
      0,
    );
  });

  testWidgets('shell animation does not relayout the workspace every frame',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var collapsed = false;
    var workspaceLayouts = 0;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return HexoraAppShell(
                globalNavigationCollapsed: collapsed,
                onRestoreGlobalNavigation: () =>
                    setState(() => collapsed = false),
                globalNav: HexoraGlobalNavBar(
                  destinations: const [
                    HexoraNavDestination(
                      id: 'income',
                      icon: Icons.receipt_long_outlined,
                      label: 'Income',
                    ),
                  ],
                  activeId: 'income',
                  onSelected: (_) {},
                  collapsed: collapsed,
                  onToggleCollapsed: () =>
                      setState(() => collapsed = !collapsed),
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    workspaceLayouts++;
                    return const SizedBox.expand();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('HEXORA').hitTestable());
    await tester.pump();
    final collapseLayouts = workspaceLayouts;
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(workspaceLayouts, collapseLayouts);
    await tester.pumpAndSettle();

    rebuild(() => collapsed = false);
    await tester.pump();
    final expandLayouts = workspaceLayouts;
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(workspaceLayouts, expandLayouts);
    await tester.pumpAndSettle();
    expect(workspaceLayouts, lessThanOrEqualTo(expandLayouts + 1));
  });

  testWidgets('resizing the shell does not overflow navigation controls',
      (tester) async {
    tester.view.physicalSize = const Size(760, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HexoraAppShell(
            globalNav: HexoraGlobalNavBar(
              destinations: const [
                HexoraNavDestination(
                  id: 'income',
                  icon: Icons.receipt_long_outlined,
                  label: 'Income',
                ),
                HexoraNavDestination(
                  id: 'expenses',
                  icon: Icons.trending_down_rounded,
                  label: 'Expenses',
                ),
                HexoraNavDestination(
                  id: 'bank',
                  icon: Icons.account_balance_outlined,
                  label: 'Bank',
                ),
                HexoraNavDestination(
                  id: 'calendar',
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar',
                ),
              ],
              activeId: 'income',
              onSelected: (_) {},
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
