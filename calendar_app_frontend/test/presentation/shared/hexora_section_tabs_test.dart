import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';

void main() {
  for (final width in [320.0, 1000.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('section tabs and date actions width $width $brightness',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final controller = TabController(length: 4, vsync: tester);
        addTearDown(controller.dispose);
        var range = DateQuickRange.none;
        var expanded = false;
        DateTime? from;
        var downloads = 0;
        var pickedFrom = 0;
        var pickedTo = 0;
        final zipKey = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          theme:
              AppTheme.forPlatform(brightness, platform: TargetPlatform.windows)
                  .copyWith(platform: TargetPlatform.windows),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(width < 500 ? 1.5 : 1)),
              child: child!),
          home: Scaffold(
              body: StatefulBuilder(
                  builder: (context, setState) => Column(children: [
                        HexoraSectionTabs(controller: controller, tabs: const [
                          Tab(text: 'Facturas (9)'),
                          Tab(text: 'Recibos (10)'),
                          Tab(text: 'Contratos (0)'),
                          Tab(text: 'Gráfico')
                        ]),
                        const SizedBox(height: 8),
                        DateRangeFilterCard(
                          quickRange: range,
                          expanded: expanded,
                          fromDate: from,
                          toDate: null,
                          onToggleExpanded: () =>
                              setState(() => expanded = !expanded),
                          onClear: () => setState(() {
                            range = DateQuickRange.none;
                            from = null;
                          }),
                          onPickFrom: () => pickedFrom++,
                          onPickTo: () => pickedTo++,
                          onSelectQuickRange: (value) => setState(() {
                            range = value;
                            expanded = value == DateQuickRange.custom;
                            from = DateTime(2026, 1, 1);
                          }),
                          trailingActions: [
                            TextButton(
                                key: zipKey,
                                style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                onPressed: () => downloads++,
                                child: const Text('ZIP (9)'))
                          ],
                        ),
                      ]))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.widget<TabBar>(find.byType(TabBar)).indicator,
            isA<UnderlineTabIndicator>());
        if (width > 500) {
          expect(tester.getSize(find.byType(HexoraSectionTabs)).height, 36);
          expect(tester.getSize(find.byType(DateRangeFilterCard)).height, 32);
          expect(
              tester.getCenter(find.byKey(zipKey)).dx,
              greaterThan(tester
                  .getCenter(find.byKey(const ValueKey('date-range-custom')))
                  .dx));
        }
        for (final value in [
          DateQuickRange.month,
          DateQuickRange.quarter,
          DateQuickRange.custom
        ]) {
          await tester.tap(find.byKey(ValueKey('date-range-${value.name}')));
          await tester.pumpAndSettle();
          expect(range, value);
          expect(tester.takeException(), isNull);
        }
        expect(expanded, isTrue);
        final l = AppLocalizations.of(
            tester.element(find.byType(DateRangeFilterCard)))!;
        await tester.tap(find.text(l.eventEndDateHint));
        expect(pickedTo, 1);
        await tester.tap(find.byKey(const ValueKey('date-range-custom')));
        await tester.pumpAndSettle();
        expect(expanded, isFalse);
        await tester.tap(find.byKey(zipKey));
        expect(downloads, 1);
        await tester.tap(find.text(l.clearSelection));
        await tester.pumpAndSettle();
        expect(range, DateQuickRange.none);
        expect(from, isNull);
        expect(pickedFrom, 0);
        await tester.drag(find.byType(TabBar), const Offset(-700, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gráfico'));
        await tester.pumpAndSettle();
        expect(controller.index, 3);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
