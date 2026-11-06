import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_month_navigator.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('navigates across years and opens a compact month popover',
      (tester) async {
    await initializeDateFormatting('es');
    var selected = DateTime(2025, 12, 1);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromBrightness(Brightness.light),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: StatefulBuilder(
            builder: (context, setState) => WorkerMonthNavigator(
              selectedMonth: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('worker-month-navigation')))
          .height,
      32,
    );
    expect(find.byTooltip('Mes anterior'), findsOneWidget);
    expect(find.byTooltip('Mes siguiente'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('worker-month-next')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 1, 1));
    expect(find.textContaining('2026'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('worker-month-previous')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2025, 12, 1));

    await tester.tap(find.byKey(const ValueKey('worker-month-open')));
    await tester.pumpAndSettle();

    final popover = find.byKey(const ValueKey('worker-month-popover'));
    expect(popover, findsOneWidget);
    expect(tester.getSize(popover).width, inInclusiveRange(240, 280));
    for (var month = 1; month <= 12; month++) {
      expect(find.byKey(ValueKey('worker-month-$month')), findsOneWidget);
    }
    expect(find.text('Mes actual'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('worker-month-10')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2025, 10, 1));
    expect(find.textContaining('Oct 2025'), findsOneWidget);
  });
}
