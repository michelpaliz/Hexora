import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/navigation_group.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/presentation/shared/widgets/navigation_menu_header.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/shared/widgets/secondary_sidebar_header.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
import 'package:hexora/theme/colors/app_colors.dart';
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
      await tester.tap(find.text('RESOURCES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Images'));
      await tester.pump();
      await tester.tap(find.text('RESOURCES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RESOURCES'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<SidebarItem>(find.widgetWithText(SidebarItem, 'Images'))
              .isSelected,
          isTrue);
      expect(find.text('RESOURCES'), findsOneWidget);
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

  testWidgets('sidebar typography keeps a clear hierarchy', (tester) async {
    TextStyle styleOf(String text) =>
        tester.widget<Text>(find.text(text)).style!;
    Color iconColorOf(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color!;

    await tester.pumpWidget(MaterialApp(
        theme: navigationTheme(ThemeData(platform: TargetPlatform.windows)),
        home: Scaffold(
            body: SizedBox(
                width: 248,
                child: Column(children: [
                  NavigationMenuHeader(
                      title: 'Ingresos',
                      icon: Icons.receipt_long_outlined,
                      onToggle: () {}),
                  NavigationGroup(
                      title: 'Clientes',
                      icon: Icons.people_outline,
                      expanded: false,
                      onToggle: () {},
                      child: const SizedBox.shrink()),
                  const GroupInvoicesSectionLabel('Facturas'),
                  SidebarItem(
                      icon: Icons.add_rounded,
                      label: 'Crear factura',
                      isSelected: false,
                      collapsed: false,
                      primaryAction: true,
                      onTap: () {}),
                  SidebarItem(
                      icon: Icons.repeat_rounded,
                      label: 'Recurrentes',
                      isSelected: false,
                      collapsed: false,
                      count: 3,
                      onTap: () {}),
                  SidebarItem(
                      icon: Icons.home_outlined,
                      label: 'Facturas emitidas',
                      isSelected: true,
                      collapsed: false,
                      onTap: () {}),
                ])))));

    // The module title is no longer repeated inside the side menu header.
    expect(find.text('Ingresos'), findsNothing);
    expect(styleOf('CLIENTES').fontSize, lessThanOrEqualTo(11));
    expect(styleOf('CLIENTES').fontWeight, FontWeight.w600);
    expect(styleOf('FACTURAS').fontSize, lessThanOrEqualTo(11));
    expect(styleOf('Recurrentes').fontSize, 12.5);
    expect(styleOf('Recurrentes').fontWeight, FontWeight.w500);
    expect(styleOf('Crear factura').fontSize, lessThan(12.5));
    expect(styleOf('Crear factura').fontWeight, FontWeight.w500);
    expect(styleOf('3').fontSize, 11);
    expect(styleOf('3').fontWeight, FontWeight.w600);
    expect(styleOf('Facturas emitidas').fontWeight, FontWeight.w600);
    expect(styleOf('Facturas emitidas').color, Colors.white);

    // The creation action is neutral text with a blue icon and no fill.
    final colors =
        NavigationColors(navigationTheme(ThemeData.light()).colorScheme);
    expect(styleOf('Crear factura').color, colors.createActionForeground);
    expect(iconColorOf(Icons.add_rounded), colors.createActionIcon);
    final createFill = tester.widget<Material>(find
        .ancestor(
            of: find.text('Crear factura'), matching: find.byType(Material))
        .first);
    expect(createFill.color, Colors.transparent);

    // Muted levels stay readable on both navy navigation backgrounds.
    double contrast(Color color, Color background) {
      final blended = Color.alphaBlend(color, background);
      final a = blended.computeLuminance();
      final b = background.computeLuminance();
      return (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
    }

    for (final background in [
      AppDarkColors.sidebar,
      AppColors.dashboardTopBar
    ]) {
      expect(contrast(colors.sectionForeground, background),
          greaterThanOrEqualTo(4.5));
      expect(contrast(colors.createActionForeground, background),
          greaterThanOrEqualTo(4.5));
      expect(contrast(colors.itemForeground, background),
          greaterThan(contrast(colors.createActionForeground, background)));
    }
    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
      'sidebar edge handle stays centered at different viewport heights',
      (tester) async {
    var taps = 0;
    const handleKey = ValueKey('centered-sidebar-handle');
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final collapsed in [false, true]) {
      for (final height in [420.0, 760.0]) {
        tester.view.physicalSize = Size(800, height);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: collapsed
                    ? CollapsibleSidebar.collapsedWidth
                    : CollapsibleSidebar.expandedWidth,
                height: height,
                child: SidebarEdgeShell(
                  collapsed: collapsed,
                  onToggle: () => taps++,
                  toggleKey: handleKey,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ));

        final renderedHeight =
            tester.getSize(find.byType(SidebarEdgeShell)).height;
        expect(tester.getCenter(find.byKey(handleKey)).dy,
            closeTo(renderedHeight / 2, 0.1));
        await tester.tap(find.byKey(handleKey));
      }
    }

    expect(taps, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed navigation groups expose their destinations',
      (tester) async {
    var selected = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: CollapsibleSidebar.collapsedWidth,
            child: CollapsedNavigationGroup(
              title: 'Invoices',
              icon: Icons.receipt_long_outlined,
              destinations: [
                CollapsedNavigationDestination(
                  label: 'Issued invoices',
                  icon: Icons.description_outlined,
                  onTap: () => selected = true,
                ),
              ],
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.byTooltip('Invoices'));
    await tester.pumpAndSettle();
    expect(find.text('Issued invoices'), findsOneWidget);

    await tester.tap(find.text('Issued invoices'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared sidebar footer stays outside the scrolling viewport',
      (tester) async {
    const footerKey = ValueKey('shared-sidebar-footer');
    const contentKey = ValueKey('shared-sidebar-content');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: CollapsibleSidebar.expandedWidth,
            height: 420,
            child: SidebarFooterScope(
              builder: (_, collapsed) => Container(
                key: footerKey,
                alignment: Alignment.center,
                child: Text(collapsed ? 'Collapsed profile' : 'Profile'),
              ),
              child: SidebarEdgeShell(
                collapsed: false,
                onToggle: () {},
                child: const SizedBox.expand(key: contentKey),
              ),
            ),
          ),
        ),
      ),
    ));

    final shellRect = tester.getRect(find.byType(SidebarEdgeShell));
    final footerRect = tester.getRect(find.byKey(footerKey));
    final contentRect = tester.getRect(find.byKey(contentKey));
    expect(footerRect.bottom, closeTo(shellRect.bottom, 0.1));
    expect(contentRect.bottom, closeTo(footerRect.top, 0.1));
    expect(find.text('Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('secondary sidebar header keeps its collapse action by the title',
      (tester) async {
    var collapsed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 220,
          child: SecondarySidebarHeader(
            title: 'Importar JSON',
            onCollapse: () => collapsed = true,
          ),
        ),
      ),
    ));

    final titleRect = tester.getRect(find.text('IMPORTAR JSON'));
    final buttonRect = tester.getRect(find.byType(IconButton));
    expect(buttonRect.left - titleRect.right, closeTo(6, 0.1));

    await tester.tap(find.byType(IconButton));
    expect(collapsed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
