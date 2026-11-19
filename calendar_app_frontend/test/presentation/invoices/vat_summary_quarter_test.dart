import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/vat_summary/vat_summary_quarter.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  testWidgets('uses compact horizontal bars and independent comparisons',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 720,
            child: VatQuarterSummary(
              loading: false,
              error: null,
              data: const {
                'salesBase': 5000,
                'salesVat': 500,
                'purchaseBase': 3000,
                'purchaseVat': 400,
                'netVat': 100,
                'totalInvoices': 5,
                'totalExpenses': 1,
                'comparisonAvailable': true,
                'comparison': {
                  'previousQuarter': {
                    'quarter': 'T2',
                    'salesVat': 400,
                    'purchaseVat': 300,
                    'netVat': 100,
                  },
                  'salesVatChangePercent': 9.2,
                },
              },
              expenseEntries: const [
                {
                  'id': 'expense-1',
                  'providerName': 'Proveedor',
                  'subtotal': 3000,
                  'taxTotal': 450,
                  'total': 3450,
                },
              ],
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('\u2191 9,2% vs. T2'), findsOneWidget);
    expect(find.text('\u2191 33,3% vs. T2'), findsOneWidget);
    expect(find.text('\u2192 0,0% vs. T2'), findsOneWidget);
    expect(find.textContaining('IVA registrado: 450,00'), findsOneWidget);

    final chart = tester.widget<SfCartesianChart>(
      find.byType(SfCartesianChart),
    );
    expect(chart.series, hasLength(2));
    expect(chart.series.every((series) => series is BarSeries), isTrue);
    expect(_barValue(chart, seriesIndex: 0, pointIndex: 0), closeTo(0, 0.01));

    await tester.pump(const Duration(milliseconds: 375));
    final midwayChart = tester.widget<SfCartesianChart>(
      find.byType(SfCartesianChart),
    );
    final midwaySalesBase =
        _barValue(midwayChart, seriesIndex: 0, pointIndex: 0);
    expect(midwaySalesBase, greaterThan(0));
    expect(midwaySalesBase, lessThan(5000));

    await tester.pump(const Duration(milliseconds: 400));
    final completedChart = tester.widget<SfCartesianChart>(
      find.byType(SfCartesianChart),
    );
    expect(
      _barValue(completedChart, seriesIndex: 0, pointIndex: 0),
      closeTo(5000, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sums quarter expense VAT when the fiscal purchase total is zero',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 720,
            child: VatQuarterSummary(
              loading: false,
              error: null,
              data: const {
                'salesBase': 5000,
                'salesVat': 500,
                'purchaseBase': 0,
                'purchaseVat': 0,
                'netVat': 500,
                'totalInvoices': 5,
                'totalExpenses': 1,
              },
              expenseSummary: const {
                'count': 1,
                'subtotal': 3000,
                'taxTotal': 450,
                'total': 3450,
              },
              expenseEntries: const [
                {
                  'id': 'expense-1',
                  'providerName': 'Proveedor',
                  'subtotal': 3000,
                  'taxTotal': 450,
                  'total': 3450,
                },
              ],
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('450,00'), findsOneWidget);
    expect(find.text('50,00'), findsOneWidget);
    expect(
      find.text('Sumado desde los gastos registrados del trimestre'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

double _barValue(
  SfCartesianChart chart, {
  required int seriesIndex,
  required int pointIndex,
}) {
  final dynamic series = chart.series[seriesIndex];
  final dynamic datum = series.dataSource[pointIndex];
  final dynamic mapped = series.yValueMapper(datum, pointIndex);
  return (mapped as num?)?.toDouble() ?? 0;
}
