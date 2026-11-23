import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/widgets/calendar_side_menu.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/widgets/calendar_workspace_surfaces.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: AppColors.workspaceCanvas,
        body: child,
      ),
    );

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

ColorScheme _cs(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold))).colorScheme;

BoxDecoration _decoration(WidgetTester tester, Finder finder) {
  final container = tester.widget(finder) is Container
      ? finder
      : find.descendant(of: finder, matching: find.byType(Container)).first;
  return tester.widget<Container>(container).decoration! as BoxDecoration;
}

Widget _sideMenu({String selected = 'tasks'}) => SizedBox(
      height: 900,
      child: Row(children: [
        CalendarSideMenu(
          group: Group(
            id: 'g',
            name: 'Cabo del Sol',
            ownerId: 'u',
            userRoles: const {},
            userIds: const [],
            createdTime: DateTime(2026),
            description: '',
          ),
          collapsed: false,
          onToggleCollapse: () {},
          viewsExpanded: true,
          eventsExpanded: true,
          insightsExpanded: false,
          onToggleViewsExpanded: () {},
          onToggleEventsExpanded: () {},
          onToggleInsightsExpanded: () {},
          selectedMenu: selected,
          onMenuChanged: (_) {},
          canAddEvents: true,
          onAddEvent: () {},
          dateNavigator: const SizedBox(height: 240),
        ),
        const Expanded(child: SizedBox()),
      ]),
    );

void main() {
  group('left sidebar', () {
    testWidgets(
        'light: white sidebar, blue mini calendar card and '
        'white selected row', (tester) async {
      await _size(tester, const Size(1280, 900));
      await tester.pumpWidget(_app(_sideMenu()));
      await tester.pump();
      final cs = _cs(tester);

      expect(
        tester
            .widget<SidebarEdgeShell>(find.byType(SidebarEdgeShell))
            .backgroundColor,
        cs.surface,
      );
      expect(
        _decoration(tester,
                find.byKey(const ValueKey('calendar-mini-calendar-card')))
            .color,
        AppColors.workspaceCanvas,
      );

      final selected = tester.widget<SidebarItem>(
          find.byWidgetPredicate((w) => w is SidebarItem && w.isSelected));
      expect(selected.selectedBackgroundColor, cs.surface);
      expect(selected.selectedBorderColor, isNotNull);
      final rowMaterial = tester.widget<Material>(find
          .descendant(
            of: find.byWidget(selected),
            matching: find.byType(Material),
          )
          .first);
      expect(rowMaterial.color, cs.surface);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark keeps the navy sidebar', (tester) async {
      await _size(tester, const Size(1280, 900));
      await tester.pumpWidget(_app(_sideMenu(), brightness: Brightness.dark));
      await tester.pump();
      expect(
        tester
            .widget<SidebarEdgeShell>(find.byType(SidebarEdgeShell))
            .backgroundColor,
        AppDarkColors.sidebar,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('center', () {
    for (final brightness in Brightness.values) {
      testWidgets('toolbar is one compact white card ($brightness)',
          (tester) async {
        await _size(tester, const Size(700, 400));
        await tester.pumpWidget(_app(
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topCenter,
              child: CalendarToolbarCard(actions: [
                for (var i = 0; i < 12; i++)
                  OutlinedButton(onPressed: () {}, child: Text('Control $i')),
              ]),
            ),
          ),
          brightness: brightness,
        ));
        final card = find.byKey(const ValueKey('calendar-toolbar-card'));
        final deco = _decoration(tester, card);
        expect(deco.color, _cs(tester).surface);
        expect(deco.borderRadius, BorderRadius.circular(12));
        expect(tester.getSize(card).height, lessThanOrEqualTo(50));
        // Many controls scroll horizontally instead of overflowing.
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('right panel', () {
    Widget panel(Widget child) => Center(
          child: SizedBox(width: 320, height: 800, child: child),
        );

    for (final brightness in Brightness.values) {
      testWidgets('empty state is a compact card at the top ($brightness)',
          (tester) async {
        await _size(tester, const Size(1280, 900));
        var closed = 0;
        String? opened;
        await tester.pumpWidget(_app(
          panel(CalendarEmptyDetailsCard(
            title: 'Detalles del evento',
            message: 'Ningún evento seleccionado',
            hint:
                'Selecciona un evento del calendario para consultar sus detalles.',
            actionsTitle: 'Acciones rápidas',
            onClose: () => closed++,
            actions: [
              CalendarQuickAction(
                key: const ValueKey('quick-upcoming'),
                icon: LucideIcons.calendarClock,
                label: 'Próximos',
                onPressed: () => opened = 'upcoming',
              ),
              CalendarQuickAction(
                icon: LucideIcons.listChecks,
                label: 'Tareas',
                onPressed: () => opened = 'tasks',
              ),
            ],
          )),
          brightness: brightness,
        ));
        final card = find.byKey(const ValueKey('calendar-empty-details-card'));
        expect(_decoration(tester, card).color, _cs(tester).surface);
        final rect = tester.getRect(card);
        const panelTop = (900 - 800) / 2;
        expect(rect.top, panelTop, reason: 'anchored to the top');
        expect(rect.height, lessThan(320),
            reason: 'ends with its content instead of filling the panel');
        expect(find.text('Detalles del evento'), findsOneWidget);
        expect(find.text('Ningún evento seleccionado'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('quick-upcoming')));
        expect(opened, 'upcoming');
        await tester.tap(find.byKey(const ValueKey('calendar-details-close')));
        expect(closed, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('selected event card fills the panel; close stays visible',
        (tester) async {
      await _size(tester, const Size(1280, 900));
      await tester.pumpWidget(_app(panel(CalendarDetailsCard(
        title: 'Detalles',
        onClose: () {},
        child: ListView(children: [
          for (var i = 0; i < 60; i++) ListTile(title: Text('Campo $i')),
        ]),
      ))));
      final card = find.byKey(const ValueKey('calendar-details-card'));
      expect(tester.getSize(card).height, 800);
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('calendar-details-close')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
