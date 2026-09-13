import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/tax/tax_reporting_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/expenses/tax/tax_reporting_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/all_data/statements_all_data_skeleton.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(fontFamily: 'AppMenuFont', height: 1.4),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

class _Api extends TaxReportingApi {
  final requests = <TaxReportSection>[];
  Future<Map<String, dynamic>> Function(TaxReportSection) respond =
      (_) async => {};
  @override
  Future<Map<String, dynamic>> getReport(
      {required String groupId,
      required TaxReportSection section,
      required DateTime from,
      required DateTime inclusiveTo,
      required int year,
      required int quarter}) {
    requests.add(section);
    return respond(section);
  }
}

Future<void> _pump(WidgetTester tester, _Api api,
    {double width = 1200, String groupId = 'group'}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(extensions: const [_typography]),
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: TaxReportingView(groupId: groupId, api: api)),
  ));
  await tester.pump();
}

Future<void> _select(WidgetTester tester, String section) async {
  await tester.tap(find.byKey(ValueKey('tax-$section')));
  await tester.pumpAndSettle();
}

void main() {
  _Api filterApi() => _Api()
    ..respond = (_) async => {
          'totals': {
            'ingresosBase': 1110,
            'ingresosVat': 0,
            'ingresosCount': 3
          },
          'sales': {
            'byInvoice': [
              for (final entry in [
                ('INV-10', 'Cliente Uno', 1000, '2026-01-01'),
                ('INV-2', 'Cliente Uno', 10, '2026-02-01'),
                ('INV-3', 'Cliente Dos', 100, '2026-01-15'),
              ])
                {
                  'invoiceNumber': entry.$1,
                  'clientName': entry.$2,
                  'baseTotal': entry.$3,
                  'vatTotal': 0,
                  'total': entry.$3,
                  'issueDate': entry.$4,
                },
            ]
          },
        };

  Future<void> openFilter(WidgetTester tester, String column) async {
    await tester.tap(find.byKey(ValueKey('tax-column-filter-$column')));
    await tester.pumpAndSettle();
  }

  Future<void> applyFilter(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tax-apply-column-filter')));
    await tester.pumpAndSettle();
  }

  for (final legacy in [false, true]) {
    testWidgets(
        'client invoiceCount displays, sorts and filters (${legacy ? 'legacy' : 'nested'})',
        (tester) async {
      final clients = [
        {
          'clientId': 'client-a',
          'clientName': 'Cliente A',
          'invoiceCount': 12,
          'baseTotal': 150,
          'vatTotal': 26,
          'total': 176,
          'byVatRate': [
            {'rate': 21, 'baseTotal': 100, 'vatTotal': 21, 'total': 121},
            {'rate': 10, 'baseTotal': 50, 'vatTotal': 5, 'total': 55},
          ],
        },
        {
          'clientId': 'client-b',
          'clientName': 'Cliente B',
          'invoiceCount': 2,
          'baseTotal': 200,
          'vatTotal': 42,
          'total': 242,
        },
        {
          'clientId': 'client-c',
          'clientName': 'Cliente C',
          'invoiceCount': 0,
          'baseTotal': 0,
          'vatTotal': 0,
          'total': 0,
        },
      ];
      final api = _Api()
        ..respond = (_) async => {
              'totals': {
                'ingresosCount': 14,
                'ingresosBase': 350,
                'ingresosVat': 68
              },
              if (legacy)
                'ingresos_by_client': clients
              else
                'sales': {'byClient': clients},
            };
      await _pump(tester, api, width: 1600);
      await _select(tester, 'charged');
      await tester.tap(find.text('Agrupado por cliente'));
      await tester.pumpAndSettle();

      List<List<String?>> rows() => tester
          .widget<DataTable>(find.byType(DataTable))
          .rows
          .map((row) => row.cells
              .map((cell) => cell.child is Text
                  ? (cell.child as Text).data
                  : tester
                      .widget<Text>(find
                          .descendant(
                              of: find.byWidget(cell.child),
                              matching: find.byType(Text))
                          .first)
                      .data)
              .toList())
          .toList();
      expect(rows(), [
        ['Cliente A', '12', '150,00 EUR', '26,00 EUR', '176,00 EUR'],
        ['Cliente B', '2', '200,00 EUR', '42,00 EUR', '242,00 EUR'],
        ['Cliente C', '0', '0,00 EUR', '0,00 EUR', '0,00 EUR'],
      ]);

      final countHeader =
          find.byKey(const ValueKey('tax-client-column-filter-Facturas'));
      await tester.tap(countHeader);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ascendente'));
      await tester.pump();
      await applyFilter(tester);
      expect(rows().map((row) => row[1]), ['0', '2', '12']);

      await tester.tap(countHeader);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('tax-column-filter-search')), '12');
      await tester.pump();
      await applyFilter(tester);
      expect(rows(), [
        ['Cliente A', '12', '150,00 EUR', '26,00 EUR', '176,00 EUR']
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'client counts reveal invoice numbers by ID, never by shared names',
      (tester) async {
    final api = _Api()
      ..respond = (_) async => {
            'totals': {'ingresosCount': 3},
            'sales': {
              'byClient': [
                {
                  'clientId': 'a',
                  'clientName': 'Mismo nombre',
                  'invoiceCount': 2
                },
                {
                  'clientId': 'b',
                  'clientName': 'Mismo nombre',
                  'invoiceCount': 1
                },
                {'clientName': 'Mismo nombre', 'invoiceCount': 4},
              ],
              'byInvoice': [
                {'clientId': 'a', 'invoiceNumber': '282-26'},
                {
                  'client': {'_id': 'a'},
                  'invoiceNumber': '309-26'
                },
                {'clientId': 'b', 'invoiceNumber': '999-26'},
                {'clientId': 'a', 'invoiceNumber': '282-26'},
              ],
            },
          };
    await _pump(tester, api, width: 1600);
    await _select(tester, 'charged');
    await tester.tap(find.text('Agrupado por cliente'));
    await tester.pumpAndSettle();
    await tester.tap(
        find.descendant(of: find.byType(DataTable), matching: find.text('2')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<SelectableText>(find.byType(SelectableText))
            .map((text) => text.data),
        ['282-26', '309-26']);
    expect(find.text('999-26'), findsNothing);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(
        find.descendant(of: find.byType(DataTable), matching: find.text('4')));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsNothing);
    expect(
        find.text(
            'El informe incluye el recuento, pero no los números de factura de este cliente.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final legacy in [false, true]) {
    testWidgets('client numbers can come directly from grouped rows ($legacy)',
        (tester) async {
      final clients = [
        {
          'clientName': 'Cliente',
          'invoiceCount': 3,
          'invoiceNumbers': ['282-26'],
          'invoices': [
            {'invoiceNumber': '309-26'},
            {'invoiceNumber': '282-26'}
          ]
        },
      ];
      final api = _Api()
        ..respond = (_) async => {
              'totals': {'ingresosCount': 3},
              if (legacy)
                'ingresos_by_client': clients
              else
                'sales': {'byClient': clients},
            };
      await _pump(tester, api, width: 1600);
      await _select(tester, 'charged');
      await tester.tap(find.text('Agrupado por cliente'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(DataTable), matching: find.text('3')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widgetList<SelectableText>(find.byType(SelectableText))
              .map((text) => text.data),
          ['282-26', '309-26']);
      expect(find.text('2 de 3 números disponibles.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'invoice footer totals visible rows and reset restores descending invoice order',
      (tester) async {
    await _pump(tester, filterApi(), width: 1600);
    await _select(tester, 'charged');
    String footer(String column) =>
        tester.widget<Text>(find.byKey(ValueKey('tax-footer-$column'))).data!;
    expect(tester.getTopLeft(find.text('INV-10')).dy,
        lessThan(tester.getTopLeft(find.text('INV-3')).dy));
    expect(tester.getTopLeft(find.text('INV-3')).dy,
        lessThan(tester.getTopLeft(find.text('INV-2')).dy));
    expect(footer('base'), '1.110,00 EUR');
    expect(footer('vat'), '0,00 EUR');
    expect(footer('total'), '1.110,00 EUR');
    expect(find.text('3 facturas'), findsOneWidget);

    await openFilter(tester, 'Cliente');
    await tester.enterText(
        find.byKey(const ValueKey('tax-column-filter-search')), 'Uno');
    await tester.pump();
    await applyFilter(tester);
    expect(footer('base'), '1.010,00 EUR');
    expect(footer('total'), '1.010,00 EUR');
    expect(find.text('Total filtrado'), findsOneWidget);
    expect(find.text('2 facturas'), findsOneWidget);

    await openFilter(tester, 'Factura');
    await tester.tap(find.text('Ascendente'));
    await tester.pump();
    await applyFilter(tester);
    await tester.tap(find.byTooltip('Restablecer tabla'));
    await tester.pumpAndSettle();
    expect(footer('total'), '1.110,00 EUR');
    expect(tester.getTopLeft(find.text('INV-10')).dy,
        lessThan(tester.getTopLeft(find.text('INV-3')).dy));
    expect(find.byTooltip('Restablecer tabla'), findsNothing);
  });

  testWidgets(
      'invoice footer sums decimal credits and does not hide missing totals',
      (tester) async {
    final api = _Api()
      ..respond = (_) async => {
            'sales': {
              'byInvoice': [
                {
                  'invoiceNumber': '3',
                  'baseTotal': '0,10',
                  'vatTotal': '0,02',
                  'total': '0,12'
                },
                {
                  'invoiceNumber': '2',
                  'baseTotal': '0,20',
                  'vatTotal': '0,04',
                  'total': '0,24'
                },
                {
                  'invoiceNumber': '1',
                  'baseTotal': '-0,10',
                  'vatTotal': '-0,02',
                  'total': '-0,12'
                },
                {'invoiceNumber': '0', 'baseTotal': 1, 'vatTotal': 0},
              ]
            },
          };
    await _pump(tester, api, width: 1600);
    await _select(tester, 'charged');
    String footer(String column) =>
        tester.widget<Text>(find.byKey(ValueKey('tax-footer-$column'))).data!;
    expect(footer('base'), '1,20 EUR');
    expect(footer('vat'), '0,04 EUR');
    expect(footer('total'), '—');
    await openFilter(tester, 'Factura');
    await tester.tap(find.byKey(const ValueKey('tax-filter-value-0')));
    await tester.pump();
    await applyFilter(tester);
    expect(footer('base'), '0,20 EUR');
    expect(footer('total'), '0,24 EUR');
    await openFilter(tester, 'Factura');
    await tester.enterText(
        find.byKey(const ValueKey('tax-column-filter-search')), 'missing');
    await tester.pump();
    await applyFilter(tester);
    expect(footer('total'), '0,00 EUR');
    expect(find.text('0 facturas'), findsOneWidget);
  });

  testWidgets('search applies matches, combines columns and survives rebuilds',
      (tester) async {
    await _pump(tester, filterApi(), width: 1600);
    await _select(tester, 'charged');
    await openFilter(tester, 'Cliente');
    await tester.enterText(
        find.byKey(const ValueKey('tax-column-filter-search')), 'Uno');
    await tester.pump();
    expect(find.text('Aplicar (1)'), findsOneWidget);
    await applyFilter(tester);
    expect(find.text('INV-3'), findsNothing);
    expect(find.text('INV-10'), findsOneWidget);
    expect(find.text('INV-2'), findsOneWidget);

    await openFilter(tester, 'Factura');
    expect(find.byKey(const ValueKey('tax-filter-value-INV-3')), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('tax-column-filter-search')), 'INV-2');
    await tester.pump();
    await applyFilter(tester);
    expect(find.text('INV-10'), findsNothing);
    expect(find.text('INV-2'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar fechas'));
    await tester.pumpAndSettle();
    expect(find.text('INV-10'), findsNothing);
    expect(find.text('INV-3'), findsNothing);
    expect(find.text('INV-2'), findsOneWidget);

    await openFilter(tester, 'Factura');
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(const ValueKey('tax-filter-select-all')))
            .value,
        isNull);
    await tester.tap(find.byKey(const ValueKey('tax-filter-select-all')));
    await tester.pump();
    await applyFilter(tester);
    expect(find.text('INV-10'), findsOneWidget);
    expect(find.text('INV-2'), findsOneWidget);
    expect(find.text('INV-3'), findsNothing);

    await openFilter(tester, 'Factura');
    await tester.enterText(
        find.byKey(const ValueKey('tax-column-filter-search')), 'missing');
    await tester.pump();
    expect(find.text('Aplicar (0)'), findsOneWidget);
    await applyFilter(tester);
    expect(find.text('No hay resultados para estos filtros.'), findsOneWidget);
    await tester.tap(find.byTooltip('Restablecer tabla'));
    await tester.pumpAndSettle();
    expect(find.text('INV-3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sort uses numeric amounts, chronological dates and natural invoice order',
      (tester) async {
    await _pump(tester, filterApi(), width: 1600);
    await _select(tester, 'charged');
    for (final column in ['Factura', 'Base imponible']) {
      await openFilter(tester, column);
      await tester.tap(find.text('Ascendente'));
      await tester.pump();
      await applyFilter(tester);
      expect(tester.getTopLeft(find.text('INV-2')).dy,
          lessThan(tester.getTopLeft(find.text('INV-3')).dy));
      expect(tester.getTopLeft(find.text('INV-3')).dy,
          lessThan(tester.getTopLeft(find.text('INV-10')).dy));
    }
    await openFilter(tester, 'Fecha de emisión');
    expect(
        tester
            .getTopLeft(
                find.byKey(const ValueKey('tax-filter-value-15/01/2026')))
            .dy,
        lessThan(tester
            .getTopLeft(
                find.byKey(const ValueKey('tax-filter-value-01/02/2026')))
            .dy));
    await tester.tap(find.text('Ascendente'));
    await tester.pump();
    await applyFilter(tester);
    expect(tester.getTopLeft(find.text('INV-10')).dy,
        lessThan(tester.getTopLeft(find.text('INV-3')).dy));
    expect(tester.getTopLeft(find.text('INV-3')).dy,
        lessThan(tester.getTopLeft(find.text('INV-2')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter panel fits phone and keyboard, closing discards edits',
      (tester) async {
    await _pump(tester, filterApi(), width: 1600);
    await _select(tester, 'charged');
    tester.view.physicalSize = const Size(390, 640);
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('tax-column-filter-Factura'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await openFilter(tester, 'Factura');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(
        find.byKey(const ValueKey('tax-column-filter-search')), 'INV-2');
    await tester.pumpAndSettle();
    final apply = find.byKey(const ValueKey('tax-apply-column-filter'));
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    expect(tester.getRect(apply).bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('INV-10'), findsOneWidget);
    expect(find.text('INV-3'), findsOneWidget);
    expect(find.byTooltip('Restablecer tabla'), findsNothing);
  });

  for (final width in [1200.0, 390.0]) {
    testWidgets('tax menu matches Gastos typography at width $width',
        (tester) async {
      await _pump(tester, _Api(), width: width);
      await tester.pumpAndSettle();
      if (width < CollapsibleSidebar.responsiveBreakpoint) {
        await tester.tap(find.byTooltip('Menú fiscal'));
        await tester.pumpAndSettle();
      }
      final menu = find.byType(CollapsibleSidebar);
      Text label(String value) => tester
          .widget<Text>(find.descendant(of: menu, matching: find.text(value)));
      final expected = _typography.bodySmall.copyWith(
        fontSize: 12.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );
      final inactive = label('IVA repercutido').style!;
      expect(inactive, expected.copyWith(color: inactive.color));
      final active = label('IVA soportado').style!;
      expect(active,
          expected.copyWith(color: active.color, fontWeight: FontWeight.w700));
      final theme = Theme.of(tester.element(menu));
      expect(
          label('Impuestos').style,
          theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desktop period and summary cards share one aligned row',
      (tester) async {
    final api = _Api()
      ..respond = (_) async => {
            'totals': {
              'gastosBase': 52835.79,
              'gastosVat': 11095.52,
              'gastosCount': 81,
            },
            'purchases': {
              'byProvider': [
                {
                  'providerName': 'Proveedor',
                  'baseTotal': 52835.79,
                  'vatTotal': 11095.52,
                }
              ]
            }
          };
    await _pump(tester, api, width: 1600);
    await tester.pumpAndSettle();

    final filterRect =
        tester.getRect(find.byKey(const ValueKey('tax-period-filter')));
    for (final label in [
      'Base deducible',
      'IVA soportado',
      'Documentos de gasto'
    ]) {
      final cardRect =
          tester.getRect(find.byKey(ValueKey('tax-summary-card-$label')));
      expect(cardRect.top, filterRect.top);
      expect(cardRect.height, filterRect.height);
    }
  });

  testWidgets('invoice headers filter values and reset the table',
      (tester) async {
    final api = _Api()
      ..respond = (section) async => section == TaxReportSection.charged
          ? {
              'totals': {
                'ingresosBase': 300,
                'ingresosVat': 63,
                'ingresosCount': 2,
              },
              'sales': {
                'byInvoice': [
                  {
                    'invoiceNumber': 'INV-002',
                    'issueDate': '2026-08-02',
                    'clientName': 'Cliente Dos',
                    'baseTotal': 200,
                    'vatTotal': 42,
                    'total': 242,
                  },
                  {
                    'invoiceNumber': 'INV-001',
                    'issueDate': '2026-08-01',
                    'clientName': 'Cliente Uno',
                    'baseTotal': 100,
                    'vatTotal': 21,
                    'total': 121,
                  },
                ]
              }
            }
          : {};
    await _pump(tester, api, width: 1600);
    await tester.pumpAndSettle();
    await _select(tester, 'charged');

    await tester.tap(find.byKey(const ValueKey('tax-column-filter-Cliente')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('tax-filter-value-Cliente Dos')));
    await tester.tap(find.byKey(const ValueKey('tax-apply-column-filter')));
    await tester.pumpAndSettle();

    expect(find.text('Cliente Uno'), findsOneWidget);
    expect(find.text('Cliente Dos'), findsNothing);
    expect(find.byTooltip('Restablecer tabla'), findsOneWidget);

    await tester.tap(find.byTooltip('Restablecer tabla'));
    await tester.pump();
    expect(find.text('Cliente Dos'), findsOneWidget);
  });

  testWidgets(
      'VAT reports accept nested and legacy collections, including zero IVA',
      (tester) async {
    const provider = {
      'providerName': 'Proveedor IVA cero',
      'count': 2,
      'baseTotal': 200,
      'vatTotal': 0,
      'total': 200,
      'byVatRate': [
        {'rate': 0, 'baseTotal': 200, 'vatTotal': 0, 'total': 200}
      ]
    };
    final api = _Api()
      ..respond = (section) async => section == TaxReportSection.supported
          ? {
              'totals': {'gastosBase': 200, 'gastosVat': 0, 'gastosCount': 2},
              'gastos_by_provider': [provider]
            }
          : {
              'totals': {
                'ingresosBase': 400,
                'ingresosVat': 84,
                'ingresosCount': 1
              },
              'sales': {
                'byInvoice': [
                  {
                    'invoiceNumber': 'ISSUED-1',
                    'issueDate': '2026-09-10',
                    'clientName': 'Cliente Uno',
                    'baseTotal': 400,
                    'vatTotal': 84,
                    'total': 484,
                    'byVatRate': [
                      {
                        'rate': 21,
                        'baseTotal': 400,
                        'vatTotal': 84,
                        'total': 484
                      }
                    ]
                  },
                ]
              }
            };
    await _pump(tester, api);
    await tester.pumpAndSettle();
    expect(find.text('Proveedor IVA cero'), findsOneWidget);
    expect(find.text('0,00 EUR'), findsWidgets);
    await tester.tap(find.text('Proveedor IVA cero'));
    await tester.pumpAndSettle();
    expect(find.text('0 %'), findsOneWidget);
    await _select(tester, 'charged');
    expect(find.text('ISSUED-1'), findsOneWidget);
    expect(find.text('10/09/2026'), findsOneWidget);
    await tester.tap(find.text('ISSUED-1'));
    await tester.pumpAndSettle();
    expect(find.text('21 %'), findsOneWidget);
    final count = api.requests.length;
    await tester.tap(find.byTooltip('Contraer menú'));
    await tester.pumpAndSettle();
    expect(find.text('ISSUED-1'), findsOneWidget);
    await tester.tap(find.byTooltip('Expandir menú'));
    await tester.pumpAndSettle();
    expect(api.requests.length, count);
    expect(find.text('21 %'), findsOneWidget);
  });

  testWidgets('invoice breakdown stays below its row and uses backend totals',
      (tester) async {
    final api = _Api()
      ..respond = (_) async => {
            'sales': {
              'byInvoice': [
                {
                  'invoiceNumber': '282-26',
                  'baseTotal': 200,
                  'vatTotal': 42,
                  'byVatRate': {
                    '21': {'baseTotal': 200, 'vatTotal': 42, 'total': 242}
                  },
                },
                {
                  'invoiceNumber': '309-26',
                  'baseTotal': 1950.08,
                  'vatTotal': 409.52,
                  'totals': {'grandTotal': 2359.60},
                },
                {
                  'invoiceNumber': 'ZERO',
                  'baseTotal': 200,
                  'vatTotal': 42,
                  'total': 0,
                  'byVatRate': [
                    {'rate': 21, 'baseTotal': 200, 'vatTotal': 42, 'total': 242}
                  ],
                },
                {
                  'invoiceNumber': 'MIXED',
                  'baseTotal': 300,
                  'vatTotal': 52,
                  'byVatRate': [
                    {
                      'rate': 21,
                      'baseTotal': 200,
                      'vatTotal': 42,
                      'total': 242
                    },
                    {
                      'rate': 10,
                      'baseTotal': 100,
                      'vatTotal': 10,
                      'total': 110
                    },
                  ],
                },
                {
                  'invoiceNumber': 'PARTIAL',
                  'baseTotal': 300,
                  'vatTotal': 52,
                  'byVatRate': [
                    {
                      'rate': 21,
                      'baseTotal': 200,
                      'vatTotal': 42,
                      'total': 242
                    },
                  ],
                },
              ],
            },
          };
    await _pump(tester, api, width: 1600);
    await tester.pumpAndSettle();
    await _select(tester, 'charged');
    expect(find.text('242,00 EUR'), findsOneWidget);
    expect(find.text('2.359,60 EUR'), findsOneWidget);
    expect(find.text('0,00 EUR'), findsOneWidget);
    expect(find.byTooltip('El servidor no ha proporcionado el total agregado.'),
        findsNWidgets(2));
    expect(find.text('352,00 EUR'), findsNothing);
    expect(find.text('Desglose IVA · 282-26'), findsNothing);
    await tester.tap(find.text('282-26'));
    await tester.pumpAndSettle();
    final breakdown = find.text('Desglose IVA · 282-26');
    expect(tester.getTopLeft(breakdown).dy,
        greaterThan(tester.getBottomLeft(find.text('282-26')).dy));
    expect(tester.getBottomLeft(find.text('309-26')).dy,
        lessThan(tester.getTopLeft(find.text('282-26')).dy));
    expect(
        tester.getBottomLeft(find.text('21 %')).dy,
        lessThan(tester
            .getTopLeft(find.byKey(const ValueKey('tax-invoice-totals')))
            .dy));
    expect(find.text('242,00 EUR'), findsNWidgets(2));
    await tester.tap(find.text('282-26'));
    await tester.pumpAndSettle();
    expect(breakdown, findsNothing);
    expect(api.requests.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile invoice rows scroll horizontally and expand inline',
      (tester) async {
    final api = _Api()
      ..respond = (_) async => {
            'sales': {
              'byInvoice': [
                {
                  'invoiceNumber': 'MOBILE-1',
                  'baseTotal': 200,
                  'vatTotal': 42,
                  'total': 242,
                  'byVatRate': [
                    {'rate': 21, 'baseTotal': 200, 'vatTotal': 42, 'total': 242}
                  ],
                },
              ],
            },
          };
    await _pump(tester, api, width: 390);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menú fiscal'));
    await tester.pumpAndSettle();
    await _select(tester, 'charged');
    await tester.tap(find.text('MOBILE-1'));
    await tester.pumpAndSettle();
    expect(find.text('Desglose IVA · MOBILE-1'), findsOneWidget);
    final scroller = find.byKey(const PageStorageKey('vat-entries-charged'));
    await tester.drag(scroller, const Offset(-900, 0));
    await tester.pumpAndSettle();
    expect(find.text('242,00 EUR').first.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'changing active group clears previous data before loading new data',
      (tester) async {
    final response = Completer<Map<String, dynamic>>();
    final api = _Api()
      ..respond = (_) async => {
            'totals': {'gastosBase': 200, 'gastosVat': 0},
            'purchases': {
              'byProvider': [
                {'providerName': 'Old group supplier'}
              ]
            },
          };
    await _pump(tester, api);
    await tester.pumpAndSettle();
    expect(find.text('Old group supplier'), findsOneWidget);
    api.respond = (_) => response.future;
    await _pump(tester, api, groupId: 'new-group');
    expect(find.text('Old group supplier'), findsNothing);
    expect(find.byType(StatementsAllDataSkeleton), findsOneWidget);
    response.complete({});
    await tester.pumpAndSettle();
  });

  test('EUR formatting reuses app money conventions', () {
    expect(formatTaxEur(1234.56), '1.234,56 EUR');
    expect(formatTaxEur(-10.5), '-10,50 EUR');
    expect(formatTaxEur('0'), '0,00 EUR');
    expect(formatTaxEur(null), '—');
  });

  testWidgets('loading skeleton replaces tables, then empty state is shown',
      (tester) async {
    final response = Completer<Map<String, dynamic>>();
    final api = _Api()..respond = (_) => response.future;
    await _pump(tester, api);
    expect(find.byType(StatementsAllDataSkeleton), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('0,00 EUR'), findsNothing);
    response.complete({
      'totals': {'gastosCount': 0},
      'purchases': {'byProvider': []}
    });
    await tester.pumpAndSettle();
    expect(find.text('Sin datos'), findsOneWidget);
    expect(find.byType(StatementsAllDataSkeleton), findsNothing);
  });

  testWidgets('IRPF providers expand their own records', (tester) async {
    final api = _Api()
      ..respond = (_) async => {
            'totals': {
              'records': 2,
              'grossTotal': 200,
              'withheldTotal': 30,
              'payableTotal': 170
            },
            'byProvider': [
              {
                'providerId': 'p1',
                'providerName': 'Proveedor Uno',
                'taxId': 'B1234',
                'count': 1,
                'grossTotal': 100,
                'withheldTotal': 15,
                'payableTotal': 85
              },
              {
                'providerId': 'p2',
                'providerName': 'Proveedor Dos',
                'count': 1,
                'grossTotal': 100,
                'withheldTotal': 15,
                'payableTotal': 85
              },
            ],
            'records': [
              {
                'providerId': 'p1',
                'invoiceNumber': 'IRPF-001',
                'issueDate': '2026-09-01',
                'percentage': 15,
                'withheldAmount': 15,
                'grossTotal': 100,
                'payableTotal': 85
              },
              {'providerId': 'p2', 'invoiceNumber': 'IRPF-002'},
            ],
          };
    await _pump(tester, api);
    await _select(tester, 'irpf');
    expect(find.text('IRPF-001'), findsNothing);
    await tester.tap(find.text('Registros · Proveedor Uno'));
    await tester.pumpAndSettle();
    expect(find.text('IRPF-001'), findsOneWidget);
    expect(find.text('IRPF-002'), findsNothing);
    expect(find.text('15 %'), findsOneWidget);
  });

  testWidgets('EU purchases flag VAT ID review without legal validation claims',
      (tester) async {
    final api = _Api()
      ..respond = (_) async => {
            'totals': {
              'salesCount': 0,
              'purchaseCount': 1,
              'salesBase': 0,
              'purchaseBase': 100,
              'reviewRequired': 1
            },
            'sales': [],
            'purchases': [
              {
                'documentNumber': 'EU-1',
                'reviewRequired': true,
                'vatId': 'FR123',
                'country': 'DE',
                'base': 100,
                'vat': 0,
                'total': 100,
                'counterparty': 'EU Supplier'
              },
            ],
          };
    await _pump(tester, api);
    await _select(tester, 'intracommunity');
    await tester.tap(find.text('Compras UE'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar VAT ID'), findsOneWidget);
    expect(find.text('Validado'), findsNothing);
    expect(
        find.byTooltip(
            'Las operaciones se identifican mediante el país fiscal del cliente o proveedor. Los registros cuyo VAT ID no coincide con el país requieren revisión.'),
        findsOneWidget);
  });

  for (final sample in [
    (100, 'IVA estimado a pagar'),
    (-100, 'IVA estimado a compensar'),
    (0, 'Resultado equilibrado')
  ]) {
    testWidgets('quarterly result: ${sample.$2}', (tester) async {
      final api = _Api()
        ..respond = (_) async => {
              'netVat': sample.$1,
              'salesVat': 500,
              'purchaseVat': 400,
              'salesBase': 1000,
              'purchaseBase': 800,
              'totalInvoices': 5,
              'totalExpenses': 4,
              'comparisonAvailable': true,
              'comparison': {
                'previousQuarter': '2026-T2',
                'salesVatChangePercent': 12.5
              },
              'insights': [
                {'message': 'Observación del servidor'}
              ],
            };
      await _pump(tester, api);
      await _select(tester, 'quarterly');
      expect(find.text(sample.$2), findsOneWidget);
      expect(find.text('Trimestre anterior: 2026-T2'), findsOneWidget);
      expect(find.text('IVA repercutido: 12.5 %'), findsOneWidget);
      expect(find.text('Observación del servidor'), findsOneWidget);
    });
  }

  testWidgets('unavailable comparison is neutral', (tester) async {
    final api = _Api()
      ..respond = (_) async => {'netVat': 0, 'comparisonAvailable': false};
    await _pump(tester, api);
    await _select(tester, 'quarterly');
    expect(find.text('No hay datos comparables del trimestre anterior.'),
        findsOneWidget);
  });

  for (final status in [400, 401, 403, 500]) {
    testWidgets('safe $status error state and retry policy', (tester) async {
      final api = _Api()
        ..respond = (_) async =>
            throw TaxReportingException(status, 'private server trace');
      await _pump(tester, api);
      await tester.pumpAndSettle();
      expect(find.text('private server trace'), findsNothing);
      expect(find.text('Informe no disponible'), findsOneWidget);
      if (status == 401) {
        expect(find.text('Tu sesión ha caducado. Inicia sesión de nuevo.'),
            findsOneWidget);
      }
      if (status == 403) {
        expect(
            find.text(
                'No tienes permiso para consultar los impuestos de este grupo.'),
            findsOneWidget);
      }
      if (status == 400 || status == 500) {
        api.respond = (_) async => {};
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(find.text('Sin datos'), findsOneWidget);
      }
    });
  }

  testWidgets(
      'mobile uses a drawer, closes on selection and keeps filters accessible',
      (tester) async {
    final api = _Api();
    await _pump(tester, api, width: 360);
    expect(find.byType(CollapsibleSidebar), findsNothing);
    expect(find.text('Este trimestre'), findsOneWidget);
    await tester.tap(find.byTooltip('Menú fiscal'));
    await tester.pumpAndSettle();
    expect(find.byType(CollapsibleSidebar), findsOneWidget);
    await _select(tester, 'irpf');
    expect(find.byType(CollapsibleSidebar), findsNothing);
    expect(api.requests.last, TaxReportSection.irpf);
    expect(find.byTooltip('Actualizar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale requests cannot replace the current section',
      (tester) async {
    final first = Completer<Map<String, dynamic>>();
    final api = _Api()
      ..respond = (section) => section == TaxReportSection.supported
          ? first.future
          : Future.value({'netVat': 99});
    await _pump(tester, api);
    await _select(tester, 'quarterly');
    first.complete({'netVat': -99});
    await tester.pumpAndSettle();
    expect(find.text('IVA estimado a pagar'), findsOneWidget);
    expect(find.text('IVA estimado a compensar'), findsNothing);
  });
}
