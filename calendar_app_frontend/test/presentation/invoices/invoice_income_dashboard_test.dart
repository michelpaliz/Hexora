import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/client_invoice_comparison_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  for (final width in [390.0, 1450.0]) {
    testWidgets('income dashboard fits $width and switches range and chart',
        (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var refreshes = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.fromBrightness(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(12),
                child: ClientInvoiceComparisonView(
                  invoices: List.generate(
                      4,
                      (i) => Invoice(
                          id: '$i',
                          invoiceNumber: '$i',
                          groupId: 'g',
                          clientId: '$i',
                          clientName: 'Client $i',
                          total: 100 * (i + 1),
                          issuedAt: DateTime.now(),
                          paidAmount: i == 0 ? 100 : 0,
                          paidAt: i == 0 ? DateTime.now() : null)),
                  clients: const [],
                  selectedClient: null,
                  onSelectClient: (_) {},
                  onRefresh: () async {
                    refreshes++;
                  },
                ))),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();
      expect(refreshes, 1);
      await tester.tap(find.text('6 meses'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '6 meses'))
              .selected,
          isTrue);
      await tester.ensureVisible(find.byType(DropdownButton<bool>));
      await tester.tap(find.byType(DropdownButton<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gráfico de líneas').last);
      await tester.pumpAndSettle();
      final chart =
          tester.widget<SfCartesianChart>(find.byType(SfCartesianChart));
      expect(chart.series.first, isA<LineSeries>());
      await tester.ensureVisible(find.text('Ver todos'));
      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();
      expect(find.text('Client 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
