import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_history_card.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  const history = <Map<String, dynamic>>[
    {
      'id': 'older',
      'changedAt': '2026-10-20T09:00:00Z',
      'changes': [
        {'field': 'status', 'oldValue': 'draft', 'newValue': 'issued'},
      ],
    },
    {
      'id': 'newer',
      'changedAt': '2026-10-26T19:00:00Z',
      'changedByName': 'Michel',
      'reason': 'Corrección solicitada por el cliente',
      'fromVersion': 1,
      'toVersion': 2,
      'changes': [
        {
          'field': 'notes',
          'oldValue': 'No establecido',
          'newValue': 'No establecido',
        },
        {
          'field': 'totals',
          'oldValue': {'subtotal': 167.05, 'taxTotal': 35.08, 'total': 202.13},
          'newValue': {'subtotal': 163.68, 'taxTotal': 34.37, 'total': 198.05},
        },
        {
          'field': 'lines',
          'oldValue': [
            {'description': 'Mantenimiento', 'quantity': 2, 'unitPrice': 50},
          ],
          'newValue': [
            {'description': 'Mantenimiento', 'quantity': 1, 'unitPrice': 50},
          ],
        },
      ],
    },
  ];

  Widget app(Brightness brightness) => MaterialApp(
        theme: AppTheme.forPlatform(
          brightness,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: InvoiceDetailHistoryCard(
              title: 'Cambios',
              history: history,
              localeName: 'es',
              currency: 'EUR',
            ),
          ),
        ),
      );

  testWidgets('orders newest first and expands only meaningful changes',
      (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(Brightness.light));
    await tester.pumpAndSettle();

    final newer = find.byKey(const ValueKey('invoice-history-event-newer'));
    final older = find.byKey(const ValueKey('invoice-history-event-older'));
    expect(tester.getTopLeft(newer).dy, lessThan(tester.getTopLeft(older).dy));
    expect(find.text('Michel'), findsOneWidget);
    expect(find.text('Usuario desconocido'), findsOneWidget);
    expect(find.text('Estado actualizado'), findsOneWidget);
    expect(find.textContaining('Total anterior: 202,13'), findsOneWidget);
    expect(find.textContaining('Total nuevo: 198,05'), findsOneWidget);
    expect(find.textContaining('Diferencia: −4,08'), findsOneWidget);
    expect(find.textContaining('Notas:'), findsNothing);
    expect(find.textContaining('Mantenimiento · Cantidad'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('invoice-history-toggle-newer')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Notas:'), findsNothing);
    expect(
        find.textContaining('Mantenimiento · Cantidad: 2 → 1'), findsOneWidget);
    expect(find.text('Ocultar cambios'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders compact timeline in $brightness', (tester) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(brightness));
      await tester.pumpAndSettle();

      expect(find.text('Cambios'), findsOneWidget);
      expect(find.text('Factura modificada'), findsOneWidget);
      expect(find.text('Ver cambios'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
