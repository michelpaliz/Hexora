import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_rule_tab.dart';
import 'package:hexora/theme/themes/app_theme.dart';

const _original = <String, dynamic>{
  'rule': {
    'freq': 'monthly',
    'interval': 1,
    'startDate': '2026-10-23',
    'timeOfDay': '21:36',
    'timezone': 'Europe/Madrid',
    'billDay': 23,
  },
};

Future<void> _pump(
  WidgetTester tester, {
  int interval = 1,
  DateTime? start,
  String timezone = 'Europe/Madrid',
  String timezoneLabel = 'Madrid',
  Brightness brightness = Brightness.light,
  Size size = const Size(1280, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: RecurringDetailRuleTab(
        freq: 'monthly',
        intervalCtrl: TextEditingController(text: '$interval'),
        startDate: start ?? DateTime(2026, 10, 23, 21, 36),
        endType: 'never',
        endDate: null,
        countCtrl: TextEditingController(),
        billDayCtrl: TextEditingController(text: '23'),
        weekDayCtrl: TextEditingController(),
        timezoneCtrl: TextEditingController(text: timezone),
        invoiceDateMode: 'execution_day',
        invoiceDateDayCtrl: TextEditingController(),
        invoiceDateOffsetDaysCtrl: TextEditingController(text: '0'),
        invoiceDateClampPolicy: 'end_of_month',
        timezoneLabel: timezoneLabel,
        exceptions: const [],
        onFreqChanged: (_) {},
        onPickStart: () {},
        onPickStartTime: () {},
        onPickEnd: () {},
        onEndTypeChanged: (_) {},
        onTimezoneChanged: (_) {},
        onPickTimezone: () {},
        onAddException: () {},
        onRemoveException: (_) {},
        onInvoiceDateModeChanged: (_) {},
        onInvoiceDateClampPolicyChanged: (_) {},
        canManage: true,
        saving: false,
        onSave: () {},
        issueDatePolicySummary: 'Misma fecha',
        originalIssueDatePolicySummary: 'Misma fecha',
        originalSeries: _original,
        clientName: 'Cabo del Sol',
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'equivalent values are not changes (Europe/Madrid vs Madrid, '
      'stored date + timeOfDay)', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('rule-no-changes')), findsOneWidget);
    expect(find.text('No hay cambios pendientes'), findsOneWidget);
    expect(find.byKey(const ValueKey('rule-change-count')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only real changes are listed and counted', (tester) async {
    await _pump(tester, interval: 2, start: DateTime(2026, 10, 23, 9, 0));
    expect(find.text('2 cambios'), findsOneWidget);
    expect(find.text('Hora de inicio'), findsOneWidget);
    expect(find.text('21:36'), findsOneWidget);
    expect(find.text('9:00'), findsOneWidget);
    // Unchanged fields are not repeated.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('rule-change-summary')),
        matching: find.text('Mensual'),
      ),
      findsNothing,
    );
  });

  testWidgets('a real timezone change is detected', (tester) async {
    await _pump(
      tester,
      timezone: 'Atlantic/Canary',
      timezoneLabel: 'Atlantic/Canary',
    );
    expect(find.text('1 cambio'), findsOneWidget);
    expect(find.text('Madrid'), findsOneWidget);
    expect(find.text('Atlantic/Canary'), findsWidgets);
  });

  for (final brightness in Brightness.values) {
    testWidgets('two white cards on the light canvas + sticky save '
        '($brightness, narrow)', (tester) async {
      await _pump(tester, brightness: brightness, size: const Size(420, 820));
      final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      final canvas =
          tester.widget<ColoredBox>(find.byKey(const ValueKey('rule-canvas')));
      expect(canvas.color, cs.surfaceContainerLow);
      for (final key in ['rule-schedule-card', 'rule-change-summary']) {
        final card = tester.widget<Container>(find.byKey(ValueKey(key)));
        expect((card.decoration! as BoxDecoration).color, cs.surface,
            reason: key);
      }
      // The save bar is outside the scroll view, so it is always visible.
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byKey(const ValueKey('rule-save')),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('rule-save')).hitTestable(), findsOne);
      expect(tester.takeException(), isNull);
    });
  }
}
