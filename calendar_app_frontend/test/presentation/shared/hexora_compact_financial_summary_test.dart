import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_compact_financial_summary.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Widget subject({
    required bool loading,
    VoidCallback? onAlert,
    double width = 900,
    double textScale = 1,
  }) {
    return MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: HexoraCompactFinancialSummary(
              loading: loading,
              metrics: const [
                HexoraFinancialMetric(
                    label: 'Base imponible', value: '226.895,44 €'),
                HexoraFinancialMetric(label: 'IVA', value: '47.235,03 €'),
                HexoraFinancialMetric(
                  label: 'Total facturado',
                  value: '274.130,47 €',
                  emphasized: true,
                ),
              ],
              alert: HexoraFinancialAlert(
                label: '1 desajuste',
                tooltip: 'Abrir factura',
                onPressed: onAlert,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses one compact row and invokes discrepancy action',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(subject(loading: false, onAlert: () => taps++));

    final summary = find.byType(HexoraCompactFinancialSummary);
    expect(tester.getSize(summary).height, lessThanOrEqualTo(65));
    expect(find.text('274.130,47 €'), findsOneWidget);
    await tester.tap(find.text('1 desajuste'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading state does not show financial zeros', (tester) async {
    await tester.pumpWidget(subject(loading: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('226.895,44 €'), findsNothing);
    expect(find.text('274.130,47 €'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps without overflow on narrow enlarged layouts',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      subject(loading: false, width: 300, textScale: 2),
    );

    expect(find.text('274.130,47 €'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
