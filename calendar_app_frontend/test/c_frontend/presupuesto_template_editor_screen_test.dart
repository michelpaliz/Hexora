import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_template_editor_screen.dart';

void main() {
  testWidgets(
    'cleaning type is selected before editing and exposes its dynamic table',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = _FakePresupuestosApi();
      await tester.pumpWidget(
        MaterialApp(
          home: PresupuestoTemplateEditorScreen(
            api: api,
            groupId: 'group-1',
            createDocumentDraft: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mantenimiento anual de jardin y piscina'), findsOne);
      expect(
        find.text('Limpieza anual de escaleras y zonas comunes'),
        findsOne,
      );
      expect(find.text('Selecciona una plantilla'), findsOne);
      expect(api.defaultDocumentCreates, 0);

      await tester.tap(find.text('Usar plantilla').last);
      await tester.pumpAndSettle();

      expect(api.defaultDocumentCreates, 0);
      expect(find.text('Seleccionada'), findsOne);
      expect(find.textContaining('Imagenes'), findsNothing);

      await tester.tap(find.text('2. Datos'));
      await tester.pumpAndSettle();

      expect(find.textContaining('FRECUENCIA_MENSUAL'), findsWidgets);
      expect(find.textContaining('PRECIO_VISITA'), findsWidgets);
      expect(find.textContaining('TOTAL_MENSUAL'), findsWidgets);
      expect(find.textContaining('DURACION_CONTRATO'), findsWidgets);
      expect(find.textContaining('PREAVISO'), findsWidgets);
      expect(find.text('Nombre del cliente [CLIENTE]'), findsOne);
      expect(find.text('Total mensual [TOTAL_MENSUAL]'), findsOne);
      expect(find.textContaining('PRECIO_HORA'), findsNothing);
      expect(find.textContaining('PRECIO_PISCINA_PRIVADA'), findsNothing);
      expect(find.textContaining('ZONAS_COMUNES'), findsNothing);
      expect(find.textContaining('PRODUCTOS_INCLUIDOS'), findsNothing);
      expect(find.textContaining('DIAS_TEMPORADA_ALTA'), findsNothing);
      expect(find.textContaining('FRECUENCIA_TEMPORADA_BAJA'), findsNothing);
      expect(find.textContaining('IMPORTE_MENSUAL'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('variable_CLIENTE')),
            )
            .enabled,
        isTrue,
      );
      final dateField = tester.widget<TextField>(
        find.byKey(const ValueKey('variable_FECHA')),
      );
      expect(dateField.readOnly, isTrue);
      expect(dateField.enabled, isFalse);
      expect(dateField.controller!.text, '17/08/2026');
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('variable_TOTAL_MENSUAL')),
            )
            .controller!
            .text,
        '1.920 €',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('variable_FRECUENCIA_MENSUAL')),
            )
            .controller!
            .text,
        '4 veces al mes',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('variable_PRECIO_VISITA')),
            )
            .controller!
            .text,
        '480 €',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('variable_DURACION_CONTRATO')),
            )
            .controller!
            .text,
        'un (1) año',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('variable_PREAVISO')),
            )
            .controller!
            .text,
        'un (1) mes',
      );
      await tester.enterText(
        find.byKey(const ValueKey('variable_FRECUENCIA_MENSUAL')),
        '8',
      );
      await tester.enterText(
        find.byKey(const ValueKey('variable_PRECIO_VISITA')),
        '500 €',
      );
      await tester.pump();
      final totalField = tester.widget<TextField>(
        find.byKey(const ValueKey('variable_TOTAL_MENSUAL')),
      );
      expect(totalField.enabled, isFalse);
      expect(totalField.controller!.text, '4.000 €');

      tester
          .widget<ChoiceChip>(
            find.ancestor(
              of: find.text('3. Secciones'),
              matching: find.byType(ChoiceChip),
            ),
          )
          .onSelected!(true);
      await tester.pumpAndSettle();

      expect(find.text('Tabla'), findsOne);
      expect(find.text('Anadir fila'), findsOne);
      expect(find.text('Encabezado'), findsNothing);
      expect(find.text('Selecciona meses'), findsOne);
      expect(find.byType(Scrollbar), findsWidgets);
      final frequencyCell = find.byKey(const ValueKey('table_cell_0_1'));
      expect(tester.widget<TextField>(frequencyCell).readOnly, isFalse);
      expect(tester.widget<TextField>(frequencyCell).enabled, isNot(false));
      expect(tester.getSize(frequencyCell).width, lessThan(140));
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('table_cell_0_3')),
            )
            .readOnly,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('table_cell_0_2')),
            )
            .controller!
            .text,
        '500 €',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('table_cell_0_3')),
            )
            .controller!
            .text,
        '2.000 €',
      );
      await tester.enterText(
        find.byKey(const ValueKey('table_cell_0_1')),
        '8',
      );
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('table_cell_0_3')),
            )
            .controller!
            .text,
        '4.000 €',
      );
      tester.widget<Checkbox>(find.byType(Checkbox).at(1)).onChanged!(true);
      tester.widget<Checkbox>(find.byType(Checkbox).at(2)).onChanged!(true);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('table_bulk_1')),
        '8',
      );
      await tester.enterText(
        find.byKey(const ValueKey('table_bulk_2')),
        '500 €',
      );
      final applyButton = find.textContaining('Aplicar a');
      expect(applyButton, findsOne);
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: applyButton,
              matching: find.bySubtype<FilledButton>(),
            ),
          )
          .onPressed!();
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('table_cell_0_3')),
            )
            .controller!
            .text,
        '4.000 €',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('table_cell_2_3')),
            )
            .controller!
            .text,
        '2.000 €',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('table_cell_1_3')),
            )
            .controller!
            .text,
        '4.000 €',
      );

      await tester.scrollUntilVisible(
        find.text('Guardar borrador'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar borrador'));
      await tester.pumpAndSettle();

      expect(api.defaultDocumentCreates, 1);
      expect(api.lastDefaultKey, 'stair_cleaning_annual_maintenance');
      expect(api.lastDocumentContent!.containsKey('clientId'), isFalse);
      expect(
        (api.lastDocumentContent!['variables'] as Map).keys.toSet(),
        <String>{
          'CLIENTE',
          'FECHA',
          'MES',
          'ANO',
          'FRECUENCIA_MENSUAL',
          'PRECIO_VISITA',
          'TOTAL_MENSUAL',
          'DURACION_CONTRATO',
          'PREAVISO',
          'FRECUENCIA_LIMPIEZA_GARAJE',
          'PRECIO_LIMPIEZA_GARAJE',
        },
      );
      expect(
        api.lastDocumentContent!['title'],
        'Limpieza anual de escaleras y zonas comunes',
      );
      expect(
        (api.lastDocumentContent!['totals'] as Map)['total'],
        28000,
      );
    },
  );

  testWidgets('garage fields follow the optional section switch',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: _FakePresupuestosApi(),
          groupId: 'group-1',
          createDocumentDraft: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar plantilla').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Datos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('FRECUENCIA_LIMPIEZA_GARAJE'), findsNothing);
    expect(find.textContaining('PRECIO_LIMPIEZA_GARAJE'), findsNothing);

    await tester.tap(find.text('3. Secciones'));
    await tester.pumpAndSettle();
    final garageTitle = find.text('Limpieza anual del garaje subterráneo');
    expect(garageTitle, findsOne);
    final garageSwitch = find.byKey(
      const ValueKey('section_enabled_underground_garage_cleaning'),
    );
    expect(tester.widget<Switch>(garageSwitch).value, isFalse);
    tester.widget<Switch>(garageSwitch).onChanged!(true);
    await tester.pumpAndSettle();

    tester
        .widget<ChoiceChip>(
          find.ancestor(
            of: find.text('2. Datos'),
            matching: find.byType(ChoiceChip),
          ),
        )
        .onSelected!(true);
    await tester.pumpAndSettle();

    expect(find.textContaining('FRECUENCIA_LIMPIEZA_GARAJE'), findsWidgets);
    expect(find.textContaining('PRECIO_LIMPIEZA_GARAJE'), findsWidgets);
    expect(
      tester
          .widget<TextField>(
            find.byKey(
              const ValueKey('variable_FRECUENCIA_LIMPIEZA_GARAJE'),
            ),
          )
          .controller!
          .text,
      'una vez al año',
    );
  });

  testWidgets('selected stored client is included when creating the document',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakePresupuestosApi();
    final searches = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: api,
          groupId: 'group-1',
          createDocumentDraft: true,
          clientSearch: (search) async {
            searches.add(search);
            return <GroupClient>[
              GroupClient(
                id: 'client-existing-1',
                name: 'Comunidad Bella Beach',
                groupId: 'group-1',
              ),
            ];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar plantilla').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Datos'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('variable_CLIENTE')),
      'Bella',
    );
    await tester.tap(find.byTooltip('Buscar clientes'));
    await tester.pumpAndSettle();
    expect(searches, <String>['Bella']);
    await tester.tap(
      find.widgetWithText(MenuItemButton, 'Comunidad Bella Beach'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('3. Secciones'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Guardar borrador'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    tester
        .widget<FilledButton>(
          find.ancestor(
            of: find.text('Guardar borrador'),
            matching: find.bySubtype<FilledButton>(),
          ),
        )
        .onPressed!();
    await tester.pumpAndSettle();

    expect(api.lastDocumentContent!['clientId'], 'client-existing-1');
    expect(
      (api.lastDocumentContent!['variables'] as Map)['CLIENTE'],
      'Comunidad Bella Beach',
    );
  });

  testWidgets('garden type retains its six image slots', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakePresupuestosApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: api,
          groupId: 'group-1',
          createDocumentDraft: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usar plantilla').first);
    await tester.pumpAndSettle();

    expect(find.text('4. Imagenes'), findsOne);
    expect(find.text('0/6 imagenes'), findsOne);
    expect(api.defaultDocumentCreates, 0);
  });

  testWidgets('switching types drops stale keys and preserves CLIENTE',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakePresupuestosApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: api,
          groupId: 'group-1',
          createDocumentDraft: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usar plantilla').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar plantilla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Datos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('FRECUENCIA_MENSUAL'), findsNothing);
    expect(find.textContaining('PRECIO_VISITA'), findsNothing);
    expect(find.textContaining('PRECIO_HORA'), findsWidgets);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('variable_CLIENTE')))
          .controller!
          .text,
      'Comunidad Limpia',
    );
  });

  testWidgets(
      'existing document uses fresh variableFields and patches only them',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _ExistingDocumentApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: api,
          groupId: 'group-1',
          presupuestoId: 'cleaning-draft-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('PRECIO_HORA'), findsNothing);
    expect(find.textContaining('PRECIO_PISCINA_PRIVADA'), findsNothing);
    expect(find.textContaining('PRECIO_VISITA'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('variable_PRECIO_VISITA')),
      '500 €',
    );
    await tester.tap(find.text('2. Secciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();

    expect(api.updatedVariables, <String, dynamic>{'PRECIO_VISITA': '500 €'});
    expect(
      (api.savedContent!['variableFields'] as List)
          .whereType<Map>()
          .map((field) => field['key'])
          .contains('PRECIO_HORA'),
      isFalse,
    );
  });

  testWidgets('legacy cleaning table infers price and total columns',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakePresupuestosApi(omitTableCalculations: true);
    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: api,
          groupId: 'group-1',
          createDocumentDraft: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usar plantilla').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Datos'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('variable_PRECIO_VISITA')),
      '1000',
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '1000',
      ),
      findsNWidgets(12),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '4.000 €',
      ),
      findsAtLeastNWidgets(12),
    );
    await tester.tap(find.text('3. Secciones'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('table_cell_0_2')))
          .controller!
          .text,
      '1000',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('table_cell_0_3')))
          .controller!
          .text,
      '4.000 €',
    );
  });
}

class _FakePresupuestosApi extends PresupuestosApi {
  _FakePresupuestosApi({this.omitTableCalculations = false});

  final bool omitTableCalculations;
  int defaultDocumentCreates = 0;
  String? lastDefaultKey;
  Map<String, dynamic>? lastDocumentContent;

  @override
  Future<Map<String, dynamic>> listDefaultTemplates() async {
    return <String, dynamic>{
      'templates': <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'garden_pool_annual_maintenance',
          'name': 'Mantenimiento anual de jardin y piscina',
          'description': 'Jardines y piscina',
          'category': 'Mantenimiento',
          'title': 'Presupuesto para [CLIENTE]',
          'variables': <String, dynamic>{
            'CLIENTE': '',
            'IMPORTE_MENSUAL': '',
          },
          'variableFields': _fields(<String>[
            'CLIENTE',
            'FECHA',
            'MES',
            'ANO',
            'PRECIO_HORA',
            'PRECIO_PISCINA_PRIVADA',
            'ZONAS_COMUNES',
            'PRODUCTOS_INCLUIDOS',
            'DIAS_TEMPORADA_ALTA',
            'FRECUENCIA_TEMPORADA_BAJA',
            'IMPORTE_MENSUAL',
            'DURACION_CONTRATO',
            'PREAVISO',
          ]),
          'sections': <Map<String, dynamic>>[],
          'images': List.generate(
            6,
            (index) => <String, dynamic>{'slot': 'photo_${index + 1}'},
          ),
        },
        <String, dynamic>{
          'key': 'stair_cleaning_annual_maintenance',
          'name': 'Limpieza anual de escaleras y zonas comunes',
          'description': 'Limpieza anual',
          'category': 'Limpieza',
          'title': 'Mantenimiento de jardines y piscinas Michel S.L',
          'variables': <String, dynamic>{
            'CLIENTE': 'Comunidad Limpia',
            'FRECUENCIA_MENSUAL': '',
            'PRECIO_VISITA': '',
            'TOTAL_MENSUAL': '',
            'DURACION_CONTRATO': '',
            'PRECIO_HORA': '25 €',
            'PRECIO_PISCINA_PRIVADA': '120 €',
          },
          'variableFields': <Map<String, dynamic>>[
            <String, dynamic>{
              'key': 'CLIENTE',
              'label': 'CLIENTE',
              'value': 'Comunidad Limpia',
              'isAutomatic': true,
            },
            ..._fields(<String>['MES', 'ANO']),
            <String, dynamic>{
              'key': 'FECHA',
              'label': 'Fecha',
              'isAutomatic': true,
              'automaticValue': '17/08/2026',
            },
            <String, dynamic>{
              'key': 'FRECUENCIA_MENSUAL',
              'label': 'FRECUENCIA_MENSUAL',
              'resolvedValue': '4 veces al mes',
            },
            <String, dynamic>{
              'key': 'PRECIO_VISITA',
              'label': 'PRECIO_VISITA',
              'automaticValue': '480 €',
            },
            <String, dynamic>{
              'key': 'TOTAL_MENSUAL',
              'label': 'TOTALMENSUAL',
              'resolvedValue': '1.920 €',
              'calculation': <String, dynamic>{
                'operation': 'multiply',
                'operands': <String>[
                  'FRECUENCIA_MENSUAL',
                  'PRECIO_VISITA',
                ],
                'format': 'currency',
                'currency': 'EUR',
                'readOnly': true,
              },
            },
            <String, dynamic>{
              'key': 'DURACION_CONTRATO',
              'label': 'DURACION_CONTRATO',
              'value': 'un (1) año',
            },
            <String, dynamic>{
              'key': 'PREAVISO',
              'label': 'PREAVISO',
              'value': 'un (1) mes',
            },
            <String, dynamic>{
              'key': 'FRECUENCIA_LIMPIEZA_GARAJE',
              'label': 'FRECUENCIA_LIMPIEZA_GARAJE',
              'resolvedValue': 'una vez al año',
            },
            <String, dynamic>{
              'key': 'PRECIO_LIMPIEZA_GARAJE',
              'label': 'PRECIO_LIMPIEZA_GARAJE',
              'value': '',
            },
          ],
          'sections': <Map<String, dynamic>>[
            <String, dynamic>{
              'key': 'monthly_plan',
              'title': 'Plan mensual',
              'body': '',
              'items': <String>[],
              'table': <String, dynamic>{
                'columns': <String>[
                  'Mes',
                  'Frecuencia',
                  'Valor por limpieza',
                  'Total mensual',
                ],
                'rows': <List<String>>[
                  for (final month in <String>[
                    'Enero',
                    'Febrero',
                    'Marzo',
                    'Abril',
                    'Mayo',
                    'Junio',
                    'Julio',
                    'Agosto',
                    'Septiembre',
                    'Octubre',
                    'Noviembre',
                    'Diciembre',
                  ])
                    <String>[month, '4', '480 €', '1.920 €'],
                ],
                if (!omitTableCalculations)
                  'computedColumns': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'targetIndex': 3,
                      'operation': 'multiply',
                      'sourceIndexes': <int>[1, 2],
                      'format': 'currency',
                      'currency': 'EUR',
                      'readOnly': true,
                    },
                  ],
              },
            },
            <String, dynamic>{
              'key': 'underground_garage_cleaning',
              'title': 'Limpieza anual del garaje subterráneo',
              'body':
                  'Frecuencia: [FRECUENCIA_LIMPIEZA_GARAJE]. Precio: [PRECIO_LIMPIEZA_GARAJE].',
              'items': <String>[
                'Limpieza de zonas de circulación y plazas de aparcamiento',
                'Retirada de residuos',
                'Programación previa con la comunidad',
              ],
              'optional': true,
              'enabled': false,
            },
          ],
          'images': <Map<String, dynamic>>[],
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> createDocumentFromDefault({
    required String key,
    required String groupId,
    required Map<String, dynamic> content,
  }) async {
    defaultDocumentCreates++;
    lastDefaultKey = key;
    lastDocumentContent = Map<String, dynamic>.from(content);
    return <String, dynamic>{'presupuestoId': 'draft-1'};
  }
}

class _ExistingDocumentApi extends PresupuestosApi {
  Map<String, dynamic>? updatedVariables;
  Map<String, dynamic>? savedContent;

  @override
  Future<Map<String, dynamic>> getTemplateContent(String presupuestoId) async {
    return <String, dynamic>{
      'content': <String, dynamic>{
        'name': 'Limpieza anual',
        'title': 'Presupuesto para [CLIENTE]',
        'pageLayout': 'cleaning_three_page',
        'variables': <String, dynamic>{
          'CLIENTE': 'Contenido antiguo',
          'PRECIO_HORA': '25 €',
          'PRECIO_PISCINA_PRIVADA': '120 €',
        },
        'variableFields': _fields(<String>[
          'CLIENTE',
          'PRECIO_HORA',
          'PRECIO_PISCINA_PRIVADA',
        ]),
        'sections': <Map<String, dynamic>>[],
        'images': <Map<String, dynamic>>[],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getTemplateVariables(
    String presupuestoId,
  ) async {
    return <String, dynamic>{
      'variables': <String, dynamic>{
        'CLIENTE': 'Comunidad Reabierta',
        'PRECIO_VISITA': '480 €',
        'PRECIO_HORA': '25 €',
      },
      'variableFields': <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'CLIENTE',
          'label': 'CLIENTE',
          'value': 'Comunidad Reabierta',
        },
        ..._fields(<String>[
          'FECHA',
          'MES',
          'ANO',
          'DURACION_CONTRATO',
        ]),
        <String, dynamic>{
          'key': 'FRECUENCIA_MENSUAL',
          'label': 'FRECUENCIA_MENSUAL',
          'value': '4',
        },
        <String, dynamic>{
          'key': 'PRECIO_VISITA',
          'label': 'PRECIO_VISITA',
          'value': '480 €',
        },
        <String, dynamic>{
          'key': 'TOTAL_MENSUAL',
          'label': 'TOTAL_MENSUAL',
          'calculation': <String, dynamic>{
            'operation': 'multiply',
            'operands': <String>[
              'FRECUENCIA_MENSUAL',
              'PRECIO_VISITA',
            ],
            'format': 'currency',
            'currency': 'EUR',
            'readOnly': true,
          },
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> saveTemplateContent(
    String presupuestoId,
    Map<String, dynamic> payload,
  ) async {
    savedContent = Map<String, dynamic>.from(payload);
    return <String, dynamic>{'presupuestoId': presupuestoId};
  }

  @override
  Future<Map<String, dynamic>> updateTemplateVariables(
    String presupuestoId, {
    required Map<String, dynamic> variables,
    String? reason,
  }) async {
    updatedVariables = Map<String, dynamic>.from(variables);
    return <String, dynamic>{'presupuestoId': presupuestoId};
  }
}

List<Map<String, dynamic>> _fields(List<String> keys) => keys
    .map((key) => <String, dynamic>{'key': key, 'label': key})
    .toList(growable: false);
