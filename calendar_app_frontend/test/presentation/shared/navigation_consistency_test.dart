import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/navigation_group.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('navigation theme preserves unrelated component themes ($brightness)',
        () {
      final base = ThemeData(brightness: brightness);
      final themed = applyNavigationComponentTheme(base);
      expect(themed.textTheme, base.textTheme);
      expect(themed.inputDecorationTheme, base.inputDecorationTheme);
      expect(themed.dataTableTheme, base.dataTableTheme);
      expect(themed.dropdownMenuTheme, base.dropdownMenuTheme);
      expect(themed.filledButtonTheme, base.filledButtonTheme);
    });

    testWidgets('keyboard navigation and disabled entries ($brightness)',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
          theme: applyNavigationComponentTheme(ThemeData(
              brightness: brightness, platform: TargetPlatform.windows)),
          home: Scaffold(
              body: SizedBox(
                  width: 248,
                  child: Column(children: [
                    SidebarItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        isSelected: true,
                        collapsed: false,
                        onTap: () => calls++),
                    const SidebarItem(
                        icon: Icons.lock_outline,
                        label: 'Disabled',
                        isSelected: false,
                        collapsed: false,
                        onTap: null),
                  ])))));
      expect(tester.getSize(find.byType(SidebarItem).first).height, 40);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 1);
      await tester.tap(find.text('Disabled'));
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('group expansion preserves destination state ($brightness)',
        (tester) async {
      var expanded = false;
      var selected = false;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
              body: StatefulBuilder(
                  builder: (context, update) => SizedBox(
                      width: 248,
                      child: NavigationGroup(
                          title: 'Resources',
                          icon: Icons.folder_outlined,
                          expanded: expanded,
                          onToggle: () => update(() => expanded = !expanded),
                          child: SidebarItem(
                              icon: Icons.image_outlined,
                              label: 'Images',
                              isSelected: selected,
                              collapsed: false,
                              onTap: () => update(() => selected = true))))))));
      expect(find.text('Images'), findsNothing);
      await tester.tap(find.text('Resources'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Images'));
      await tester.pump();
      await tester.tap(find.text('Resources'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resources'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<SidebarItem>(find.widgetWithText(SidebarItem, 'Images'))
              .isSelected,
          isTrue);
      expect(
          tester
              .widget<SidebarItem>(
                  find.widgetWithText(SidebarItem, 'Resources'))
              .isSelected,
          isFalse);
    });
  }

  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets('menus keep callbacks and touch targets at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? selected;
      await tester.pumpWidget(MaterialApp(
          theme: applyNavigationComponentTheme(
              ThemeData(platform: TargetPlatform.windows)),
          home: Scaffold(
              body: PopupMenuButton<String>(
                  onSelected: (value) => selected = value,
                  itemBuilder: (_) => const [
                        NavigationPopupMenuItem(
                            value: 'open', child: Text('Open'))
                      ],
                  child: const Text('Menu')))));
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(
          tester.getSize(find.byType(NavigationPopupMenuItem<String>)).height,
          width < 760 ? 48 : 40);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(selected, 'open');
      expect(find.text('Open'), findsNothing);
    });
  }

  testWidgets('collapsed touch rail and large text fit without overflow',
      (tester) async {
    var collapsed = true;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: StatefulBuilder(
                builder: (context, update) => CollapsibleSidebar(
                        title: 'A long module title',
                        headerIcon: Icons.folder,
                        collapsed: collapsed,
                        onToggleCollapsed: () =>
                            update(() => collapsed = !collapsed),
                        items: [
                          CollapsibleSidebarItem(
                              icon: Icons.home,
                              label: 'A long destination',
                              onTap: () {})
                        ])))));
    await tester.tap(find.byKey(const ValueKey('collapsible-sidebar-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('A long destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
