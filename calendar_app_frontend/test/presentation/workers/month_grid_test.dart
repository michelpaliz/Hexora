import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/monthly_overview/widgets/monthly_grid.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final width in [320.0, 412.0, 1000.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('month cards fit at width $width and text scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        int? selected;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.fromBrightness(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: MonthGrid(
            year: 2026,
            monthlyTotals: const {
              1: {'totalHours': 123.5, 'totalPay': 12345.6, 'currency': 'EUR'}
            },
            monthNameBuilder: (month) =>
                month == 1 ? 'Septiembre' : 'Mes $month',
            subtitleBuilder: (_) => 'Resumen',
            onTapMonth: (month) => selected = month,
          ))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Septiembre'));
        expect(selected, 1);
        await tester.scrollUntilVisible(find.text('Mes 12'), 300);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Mes 12'));
        expect(selected, 12);
      });
    }
  }
}
