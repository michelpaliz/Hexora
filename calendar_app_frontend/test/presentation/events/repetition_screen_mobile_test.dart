import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/calendar/recurrence/legacy_recurrence_rule.dart';
import 'package:hexora/presentation/screens/events/screens/repetition_dialog/dialog/repetition_dialog.dart';
import 'package:hexora/presentation/screens/events/screens/repetition_dialog/widgets/weekly_day_selector.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Future<ValueNotifier<List<Object?>?>> openPicker(
    WidgetTester tester, {
    required double width,
    required double textScale,
    LegacyRecurrenceRule? initialRule,
  }) async {
    tester.view.physicalSize = Size(width, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final result = ValueNotifier<List<Object?>?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.android,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                result.value = await Navigator.of(context).push<List<Object?>>(
                  MaterialPageRoute(
                    builder: (_) => RepetitionScreen(
                      selectedStartDate: DateTime(2026, 9, 18),
                      selectedEndDate: DateTime(2026, 9, 18),
                      initialRecurrenceRule: initialRule,
                    ),
                  ),
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    return result;
  }

  for (final (width, scale) in [(320.0, 1.5), (390.0, 1.0)]) {
    testWidgets('default recurrence confirms at ${width.toInt()}px',
        (tester) async {
      final result = await openPicker(tester, width: width, textScale: scale);

      final l =
          AppLocalizations.of(tester.element(find.byType(RepetitionScreen)))!;
      expect(find.text(l.recurrenceNever), findsOneWidget);
      expect(find.text(l.recurrenceChooseDate), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip(l.repeatIntervalIncrease));
      await tester.pumpAndSettle();
      expect(find.text(l.recurrenceDailySummary(2)), findsOneWidget);

      await tester.tap(find.text(l.confirm));
      await tester.pumpAndSettle();
      expect(find.byType(RepetitionScreen), findsNothing);
      expect(result.value?[1], isTrue);
      final rule = result.value?[0] as LegacyRecurrenceRule;
      expect(rule.repeatInterval, 2);
      expect(rule.untilDate, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('weekly days and end date are reachable on a narrow phone',
      (tester) async {
    await openPicker(tester, width: 320, textScale: 1.5);
    final l =
        AppLocalizations.of(tester.element(find.byType(RepetitionScreen)))!;

    await tester.tap(find.text(l.weekly));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyDaySelector), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text(l.recurrenceEndDate));
    await tester.tap(find.text(l.recurrenceEndDate));
    await tester.pumpAndSettle();
    expect(find.text(l.recurrenceChooseDate), findsWidgets);
    expect(tester.takeException(), isNull);

    final chooseDate = find.byKey(const Key('recurrence-date-button'));
    await tester.ensureVisible(chooseDate);
    await tester.tap(chooseDate);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing an edit keeps the existing repetition', (tester) async {
    final existing = LegacyRecurrenceRule.daily(
      repeatInterval: 3,
      startDate: DateTime(2026, 9, 18),
    );
    final result = await openPicker(
      tester,
      width: 390,
      textScale: 1,
      initialRule: existing,
    );
    final l =
        AppLocalizations.of(tester.element(find.byType(RepetitionScreen)))!;

    expect(find.text(l.removeRecurrence), findsOneWidget);
    await tester.tap(find.byTooltip(l.cancel));
    await tester.pumpAndSettle();
    expect(result.value?[0], same(existing));
    expect(result.value?[1], isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a repetition requires confirmation', (tester) async {
    final result = await openPicker(
      tester,
      width: 390,
      textScale: 1,
      initialRule: LegacyRecurrenceRule.daily(
        startDate: DateTime(2026, 9, 18),
      ),
    );
    final l =
        AppLocalizations.of(tester.element(find.byType(RepetitionScreen)))!;

    await tester.tap(find.text(l.removeRecurrence));
    await tester.pumpAndSettle();
    expect(find.text(l.removeRecurrenceConfirm), findsOneWidget);
    await tester.tap(find.text(l.remove));
    await tester.pumpAndSettle();
    expect(result.value?[0], isNull);
    expect(result.value?[1], isFalse);
    expect(tester.takeException(), isNull);
  });
}
