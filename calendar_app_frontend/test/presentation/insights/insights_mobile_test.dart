import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/graphs/enum/insights_types.dart';
import 'package:hexora/presentation/screens/workspace/sections/graphs/sections/bar/insights_bar_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/graphs/sections/filter/insights_filter_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/graphs/widgets/dimension_tabs.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('mobile report controls and long labels in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var dimension = Dimension.clients;
      var preset = RangePreset.m3;
      var picked = false;
      await tester.pumpWidget(MaterialApp(
        theme:
            AppTheme.forPlatform(brightness, platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
                  body: SafeArea(
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                        DimensionTabs(
                            value: dimension,
                            onChanged: (value) =>
                                setState(() => dimension = value)),
                        InsightsFiltersSection(
                            preset: preset,
                            onPresetChanged: (value) =>
                                setState(() => preset = value),
                            onPickCustom: () => picked = true,
                            rangeText: '11 jun 2026 – 11 sept 2026'),
                        const InsightsBarsCard(
                            title: 'Tiempo por cliente',
                            minutesByKey: {
                              'MARÍA CONCEPCIÓN MONZÓN ARAMBURU': 120,
                              'FER CAMAR GESTIÓN ALMERÍA S.L.': 60,
                            }),
                      ])),
                )),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceChip).last);
      await tester.pumpAndSettle();
      expect(dimension, Dimension.services);
      await tester.tap(find.byType(DropdownButton<RangePreset>));
      await tester.pumpAndSettle();
      final option = find.text('7d').last;
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(preset, RangePreset.d7);
      await tester.tap(find.text('11 jun 2026 – 11 sept 2026'));
      expect(picked, isTrue);
      await tester.ensureVisible(find.text('MARÍA CONCEPCIÓN MONZÓN ARAMBURU'));
      expect(find.text('2h · 67%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
