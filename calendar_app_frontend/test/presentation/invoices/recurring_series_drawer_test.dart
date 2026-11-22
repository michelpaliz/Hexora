import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_generated_tab.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_series_list_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';

Map<String, dynamic> _series({
  String id = 'series-1',
  Object? clientId = 'client-1',
  String? clientName,
  String status = 'active',
}) =>
    {
      'id': id,
      'clientId': clientId,
      if (clientName != null) 'clientName': clientName,
      'name': 'Mantenimiento de jardinería y piscina',
      'status': status,
      'currency': 'EUR',
      'totals': {'total': 2359.6},
      'rule': {'freq': 'monthly', 'interval': 1},
      'nextRunAt': '2026-11-23T08:00:00.000Z',
      'invoiceDateMode': 'fixed_day',
      'invoiceDateDay': 26,
    };

Future<void> _pump(
  WidgetTester tester, {
  required List<Map<String, dynamic>> series,
  // Client known to the list but without a usable name.
  List<GroupClient>? clients,
  bool canManage = true,
  Brightness brightness = Brightness.light,
  ValueChanged<Map<String, dynamic>>? onCancel,
  ValueChanged<Map<String, dynamic>>? onEdit,
  ValueChanged<Map<String, dynamic>>? onPause,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: RecurringSeriesListView(
        series: series,
        clients: clients ?? [GroupClient(id: 'client-1', name: '')],
        canManage: canManage,
        statusFilter: 'all',
        clientFilter: null,
        dueSoonOnly: false,
        onStatusFilter: (_) {},
        onClientFilter: (_) {},
        onDueSoon: (_) {},
        onRefresh: () {},
        onCreate: () {},
        onOpenSeries: onEdit ?? (_) {},
        onPreviewSeries: (_) {},
        onPauseSeries: onPause ?? (_) {},
        onResumeSeries: (_) {},
        onCancelSeries: onCancel ?? (_) {},
        showHeader: false,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('drawer header resolves the client name from the client list',
      (tester) async {
    await _pump(
      tester,
      series: [_series()],
      clients: [GroupClient(id: 'client-1', name: 'Cabo del Sol')],
    );
    await tester.tap(find.text('Mantenimiento de jardinería y piscina'));
    await tester.pumpAndSettle();

    final client = find.byKey(const ValueKey('recurring-drawer-client'));
    expect(tester.widget<Text>(client).data, 'Cabo del Sol');
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('recurring-drawer-service')))
          .data,
      'Mantenimiento de jardinería y piscina',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('recurring-drawer-status')),
        matching: find.text('Activa'),
      ),
      findsOneWidget,
    );
    final amount = tester
        .widget<Text>(find.byKey(const ValueKey('recurring-drawer-amount')))
        .data!;
    expect(amount, contains('2.359,60'));
    expect(amount, contains('€'));
    expect(amount, isNot(contains('EUR')));
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('recurring-drawer-next')))
          .data,
      contains('2026'),
    );
    expect(find.text('Día fijo 26'), findsOneWidget);
    expect(find.text('Fin de mes'), findsOneWidget);
    expect(find.text('Editar recurrencia'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing client shows "Cliente no disponible", never "-"',
      (tester) async {
    await _pump(tester, series: [_series()]);
    await tester.tap(find.text('Mantenimiento de jardinería y piscina'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('recurring-drawer-client')))
          .data,
      'Cliente no disponible',
    );
  });

  testWidgets('actions keep the existing handlers; cancel lives in the menu',
      (tester) async {
    Map<String, dynamic>? edited, paused, cancelled;
    await _pump(
      tester,
      series: [_series(clientName: 'Cabo del Sol')],
      onEdit: (s) => edited = s,
      onPause: (s) => paused = s,
      onCancel: (s) => cancelled = s,
    );
    await tester.tap(find.text('Mantenimiento de jardinería y piscina'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar recurrencia'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('recurring-drawer-edit')));
    expect(edited?['id'], 'series-1');
    await tester.tap(find.byKey(const ValueKey('recurring-drawer-toggle')));
    expect(paused?['id'], 'series-1');

    await tester.tap(find.byKey(const ValueKey('recurring-drawer-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar recurrencia'));
    await tester.pumpAndSettle();
    expect(cancelled?['id'], 'series-1');
  });

  testWidgets('paused series offers Reanudar', (tester) async {
    await _pump(
      tester,
      series: [_series(clientName: 'Cabo del Sol', status: 'paused')],
    );
    await tester.tap(find.text('Mantenimiento de jardinería y piscina'));
    await tester.pumpAndSettle();
    expect(find.text('Reanudar'), findsOneWidget);
    expect(find.text('Pausada'), findsWidgets);
  });

  testWidgets('read-only users see no management actions', (tester) async {
    await _pump(
      tester,
      series: [_series(clientName: 'Cabo del Sol')],
      canManage: false,
    );
    await tester.tap(find.text('Mantenimiento de jardinería y piscina'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recurring-drawer-edit')), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('drawer renders without overflow on a phone ($brightness)',
        (tester) async {
      await _pump(
        tester,
        series: [_series(clientName: 'Comunidad de Propietarios Residencial')],
        brightness: brightness,
      );
      tester.view.physicalSize = const Size(390, 760);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comunidad de Propietarios Residencial'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recurring-drawer-summary')), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'dense generated list: titled count, external preview, '
      'selected row has a left indicator only', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(460, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const invoices = [
      Invoice(
        id: 'inv-1',
        invoiceNumber: '393-26',
        groupId: 'g',
        clientId: 'c',
        status: 'issued',
        currency: 'EUR',
        total: 2359.6,
      ),
      Invoice(
        id: 'inv-2',
        invoiceNumber: '381-26',
        groupId: 'g',
        clientId: 'c',
        status: 'issued',
        currency: 'EUR',
        total: 2359.6,
      ),
    ];
    Invoice? previewed;
    var inlineLoads = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RecurringDetailGeneratedTab(
          loading: false,
          error: null,
          invoices: invoices,
          onReload: () {},
          hasRequested: true,
          count: 2,
          onDownloadPdf: (_) {},
          onLoadInvoiceDetails: (id) async =>
              invoices.firstWhere((i) => i.id == id),
          onLoadInvoicePreviewBytes: (_) async {
            inlineLoads++;
            return Uint8List(0);
          },
          toolbarTitle: 'Facturas generadas',
          dense: true,
          onPreviewInvoice: (invoice) => previewed = invoice,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Facturas generadas (2)'), findsOneWidget);
    expect(find.text('PDFs generados'), findsNothing);
    final totals = find.textContaining('2.359,60');
    expect(totals, findsNWidgets(2));
    expect(tester.widget<Text>(totals.first).data, contains('€'));

    await tester.tap(find.byKey(const ValueKey('generated-invoice-row-inv-2')));
    await tester.pumpAndSettle();
    expect(previewed?.id, 'inv-2');
    expect(inlineLoads, 0, reason: 'no PDF rendered inside the drawer');

    final selected = tester.widget<Container>(find
        .descendant(
          of: find.byKey(const ValueKey('generated-invoice-row-inv-2')),
          matching: find.byType(Container),
        )
        .first);
    final border = (selected.decoration! as BoxDecoration).border! as Border;
    final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    expect(border.left.color, cs.primary);
    expect(border.top, BorderSide.none);
    expect(tester.takeException(), isNull);
  });
}
