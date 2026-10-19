import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/templates/presupuesto_template_editor_screen.dart';

void main() {
  testWidgets('editing generated frequency preserves custom month ranges',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _ServiceDocumentApi('mantenimiento del jardín');
    api.content['sections'] = [
      {
        'key': 'work_frequency',
        'generatedFrequency': true,
        'title': 'Frecuencia',
        'items': <String>[]
      },
    ];
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      presupuestoId: 'draft-1',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Periodo personalizado conservado: Junio a septiembre'),
        findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('high_season_frequency')),
        '5 visitas por mes');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('high_season_summary')))
            .data,
        contains('Junio a septiembre'));
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    final variables = api.lastDocumentContent!['variables'] as Map;
    expect(variables['MESES_TEMPORADA_ALTA'], 'Junio a septiembre');
    expect(variables['MESES_TEMPORADA_BAJA'], 'Resto del año');
    expect(variables['DIAS_TEMPORADA_ALTA'], '5 visitas por mes');
    expect(variables['FRECUENCIA_TEMPORADA_BAJA'], '2 veces por mes');
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment conditions and annex are always the last two sections',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _ServiceDocumentApi('mantenimiento del jardín');
    api.content['sections'] = [
      {'key': 'section_1', 'order': 1, 'title': 'Anexo (algunas fotos).'},
      {
        'key': 'section_2',
        'order': 2,
        'title': 'Condiciones de pago y duración del contrato.'
      },
      {'key': 'section_3', 'order': 3, 'title': 'Control de los trabajos.'},
      {'key': 'section_4', 'order': 4, 'title': 'Referencias.'},
    ];
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      presupuestoId: 'draft-1',
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
    await tester.pumpAndSettle();
    // Pinned sections show a lock instead of a drag handle.
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    final saved = (api.lastDocumentContent!['sections'] as List)
        .map((s) => (s as Map)['title'])
        .toList();
    expect(saved, [
      'Control de los trabajos.',
      'Referencias.',
      'Condiciones de pago y duración del contrato.',
      'Anexo (algunas fotos).',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'changing saved service patches variables without rebuilding items',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _ServiceDocumentApi('Servicio personalizado de riego');
    final sections = api.content['sections'];
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      presupuestoId: 'draft-1',
    )));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('service_mantenimiento del jardín')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    expect(api.updatedVariables,
        {'SERVICIO_MANTENIMIENTO': 'mantenimiento del jardín'});
    expect(api.lastDocumentContent!['sections'], sections);
    expect(
        (api.lastDocumentContent!['variables'] as Map)['DIAS_TEMPORADA_ALTA'],
        '4 veces por mes');
    expect(
        (api.lastDocumentContent!['variables']
            as Map)['FRECUENCIA_TEMPORADA_BAJA'],
        '2 veces por mes');
    expect(tester.takeException(), isNull);
  });

  testWidgets('new service requires an explicit choice for save and preview',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _ServiceDocumentApi('limpieza de la piscina');
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      createDocumentDraft: true,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar plantilla').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Previsualizar'));
    await tester.pumpAndSettle();
    expect(api.defaultDocumentCreates, 0);
    expect(find.text('Selecciona un tipo de servicio para continuar.'),
        findsOneWidget);
    expect(
        tester
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('service_limpieza de la piscina')))
            .selected,
        isFalse);
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    expect(api.defaultDocumentCreates, 0);
    expect(find.text('Selecciona un tipo de servicio para continuar.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final service in [
    'mantenimiento del jardín y la piscina',
    'mantenimiento del jardín',
    'limpieza de la piscina',
    'Servicio personalizado de riego',
    '',
  ]) {
    testWidgets('reopen preserves service and authored payload: $service',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _ServiceDocumentApi(service);
      final originalVariables =
          Map<String, dynamic>.from(api.content['variables'] as Map);
      final originalSections = api.content['sections'];
      await tester.pumpWidget(MaterialApp(
          home: PresupuestoTemplateEditorScreen(
        api: api,
        groupId: 'group-1',
        presupuestoId: 'draft-1',
      )));
      await tester.pumpAndSettle();
      final chip = find.byKey(ValueKey('service_$service'));
      if (chip.evaluate().isNotEmpty) {
        expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      } else if (service.isNotEmpty) {
        expect(find.text('Servicio personalizado: $service'), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar borrador'));
      await tester.pumpAndSettle();
      expect(api.lastDocumentContent!['variables'], originalVariables);
      expect(api.lastDocumentContent!['sections'], originalSections);
      expect(api.lastDocumentContent!['totals'],
          {'total': 300, 'currency': 'EUR'});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('season months complement, save and reopen on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _SeasonDocumentApi();
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      createDocumentDraft: true,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar plantilla').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
    await tester.pumpAndSettle();
    final june = find.byKey(const ValueKey('high_season_month_6'));
    await tester.ensureVisible(june);
    expect(tester.widget<FilterChip>(june).selected, isTrue);
    await tester.tap(june);
    await tester.pumpAndSettle();
    expect(find.text('9 meses · Automático'), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('low_season_summary')))
            .data,
        contains('Ene, Feb, Mar, Abr, May, Jun, Oct, Nov, Dic'));
    await tester.enterText(find.byKey(const ValueKey('high_season_frequency')),
        '3 veces por semana');
    await tester.enterText(
        find.byKey(const ValueKey('low_season_frequency')), '1 vez por semana');
    final service =
        find.byKey(const ValueKey('service_limpieza de la piscina'));
    await tester.ensureVisible(service);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(service).selected, isFalse);
    await tester.tap(service);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(1600, 3000);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    final content = api.lastDocumentContent!;
    expect(content['seasonConfiguration'], {
      'highSeason': {
        'months': [7, 8, 9],
        'frequency': '3 veces por semana'
      },
      'lowSeason': {
        'months': [1, 2, 3, 4, 5, 6, 10, 11, 12],
        'frequency': '1 vez por semana'
      },
    });
    final variables = content['variables'] as Map;
    expect(variables['SERVICIO_MANTENIMIENTO'], 'limpieza de la piscina');
    expect(variables['MESES_TEMPORADA_ALTA'], 'Jul, Ago, Sep');
    expect(variables['DIAS_TEMPORADA_ALTA'], '3 veces por semana');
    expect(variables['FRECUENCIA_TEMPORADA_BAJA'], '1 vez por semana');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      presupuestoId: 'draft-1',
    )));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(june).selected, isFalse);
    expect(tester.widget<ChoiceChip>(service).selected, isTrue);
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('high_season_frequency')))
            .controller!
            .text,
        '3 veces por semana');
    expect(tester.takeException(), isNull);
  });

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

      await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('variable_FRECUENCIA_MENSUAL')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('variable_PRECIO_VISITA')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('variable_TOTAL_MENSUAL')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('variable_DURACION_CONTRATO')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('variable_PREAVISO')),
        findsOneWidget,
      );
      expect(find.text('Nombre del cliente'), findsOne);
      expect(find.text('Total mensual'), findsWidgets);
      for (final key in const <String>[
        'PRECIO_HORA',
        'PRECIO_PISCINA_PRIVADA',
        'ZONAS_COMUNES',
        'PRODUCTOS_INCLUIDOS',
        'DIAS_TEMPORADA_ALTA',
        'FRECUENCIA_TEMPORADA_BAJA',
        'IMPORTE_MENSUAL',
      ]) {
        expect(find.byKey(ValueKey('variable_$key')), findsNothing);
      }
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('variable_CLIENTE')),
            )
            .enabled,
        isTrue,
      );
      expect(find.byKey(const ValueKey('variable_FECHA')), findsNothing);
      expect(find.text('Datos automáticos'), findsOneWidget);
      expect(find.text('17/08/2026'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('variable_TOTAL_MENSUAL')),
            )
            .data,
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
      final totalField = tester.widget<Text>(
        find.byKey(const ValueKey('variable_TOTAL_MENSUAL')),
      );
      expect(totalField.data, '4.000 €');

      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('editor_step_Secciones')),
          )
          .onTap!();
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
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('variable_FRECUENCIA_LIMPIEZA_GARAJE')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('variable_PRECIO_LIMPIEZA_GARAJE')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
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
        .widget<InkWell>(
          find.byKey(const ValueKey('editor_step_Datos')),
        )
        .onTap!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('variable_FRECUENCIA_LIMPIEZA_GARAJE')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('variable_PRECIO_LIMPIEZA_GARAJE')),
      findsOneWidget,
    );
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
              for (var i = 0; i < 20; i++)
                GroupClient(
                    id: 'client-$i',
                    name: 'Otro cliente $i',
                    groupId: 'group-1'),
            ];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar plantilla').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('variable_CLIENTE')),
      'Bella',
    );
    await tester.tap(find.byTooltip('Buscar clientes'));
    await tester.pumpAndSettle();
    expect(searches, <String>['Bella']);
    final menuViewport = find
        .ancestor(
          of: find.byKey(const ValueKey('use_custom_client_name')),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(tester.getSize(menuViewport).height, lessThanOrEqualTo(320));
    expect(
        tester.getSize(menuViewport).width,
        lessThanOrEqualTo(tester
            .getSize(find.byKey(const ValueKey('variable_CLIENTE')))
            .width));
    await tester.tap(
      find.widgetWithText(MenuItemButton, 'Comunidad Bella Beach'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
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

  for (final scenario in ['no matches', 'search failure', 'saved client']) {
    testWidgets('custom client name saves without a client ID after $scenario',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _FakePresupuestosApi();
      var searches = 0;
      await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: api,
          groupId: 'group-1',
          createDocumentDraft: true,
          clientSearch: (_) async {
            searches++;
            if (scenario == 'search failure') throw Exception('Offline');
            return scenario == 'saved client'
                ? [
                    GroupClient(
                        id: 'saved-client',
                        name: 'Chalet Marcin',
                        groupId: 'group-1')
                  ]
                : <GroupClient>[];
          },
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar plantilla').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
      await tester.pumpAndSettle();
      final client = find.byKey(const ValueKey('variable_CLIENTE'));
      await tester.enterText(client, 'Chalet Marcin');
      await tester.tap(find.byTooltip('Buscar clientes'));
      await tester.pumpAndSettle();
      if (scenario == 'saved client') {
        await tester.tap(find.widgetWithText(MenuItemButton, 'Chalet Marcin'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('client_mode_custom')));
      } else {
        expect(
            find.textContaining(scenario == 'search failure'
                ? 'No se pudieron cargar'
                : 'Sin coincidencias.'),
            findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('use_custom_client_name')));
      }
      await tester.pumpAndSettle();
      expect(
          tester.widget<TextField>(client).controller!.text, 'Chalet Marcin');
      expect(find.text('Volver a clientes'), findsOneWidget);
      await tester.enterText(client, 'Chalet Marcin nuevo');
      await tester.pump(const Duration(milliseconds: 400));
      expect(searches, 1);
      expect(find.byType(MenuItemButton), findsNothing);
      await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
      await tester.pumpAndSettle();
      expect(find.text('Volver a clientes'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Guardar borrador'), 500,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Guardar borrador'));
      await tester.pumpAndSettle();
      expect(api.lastDocumentContent!.containsKey('clientId'), isFalse);
      expect((api.lastDocumentContent!['variables'] as Map)['CLIENTE'],
          'Chalet Marcin nuevo');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'custom client name is patched when an existing field is automatic',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _AutomaticClientApi();
    await tester.pumpWidget(MaterialApp(
      home: PresupuestoTemplateEditorScreen(
        api: api,
        groupId: 'group-1',
        presupuestoId: 'budget-1',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Volver a clientes'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('variable_CLIENTE')), 'Cliente nuevo');
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    expect(api.updatedVariables, {'CLIENTE': 'Cliente nuevo'});
    expect(tester.takeException(), isNull);
  });

  for (final service in <String>[
    'mantenimiento del jardín y la piscina',
    'mantenimiento del jardín',
    'limpieza de la piscina',
  ]) {
    testWidgets('service chip persists $service', (tester) async {
      tester.view.physicalSize = const Size(1600, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _ServiceDocumentApi('');
      (api.content['sections'] as List).insert(0, {
        'key': 'default_frequency',
        'order': 1,
        'enabled': true,
        'title': 'Frecuencia de trabajos',
        'body': '',
        'items': [
          'La limpieza de la piscina se realizará tres días por semana en temporada alta: [DIAS_TEMPORADA_ALTA]',
          'En temporada baja la limpieza de la piscina se realizará [FRECUENCIA_TEMPORADA_BAJA]',
        ],
      });
      await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: api,
          groupId: 'group-1',
          createDocumentDraft: true,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar plantilla').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
      await tester.pumpAndSettle();
      final chip = find.byKey(ValueKey('service_$service'));
      await tester.ensureVisible(chip);
      // Select another option first to exercise an explicit pool selection too.
      await tester.tap(find.byKey(
          const ValueKey('service_mantenimiento del jardín y la piscina')));
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      for (final key in ['high_season_summary', 'low_season_summary']) {
        expect(tester.widget<Text>(find.byKey(ValueKey(key))).data,
            contains(service));
      }
      await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar borrador'));
      await tester.tap(find.text('Guardar borrador'));
      await tester.pumpAndSettle();
      expect(
          (api.lastDocumentContent!['variables']
              as Map)['SERVICIO_MANTENIMIENTO'],
          service);
      final variables = api.lastDocumentContent!['variables'] as Map;
      expect(variables['DIAS_TEMPORADA_ALTA'], '4 veces por mes');
      expect(variables['FRECUENCIA_TEMPORADA_BAJA'], '2 veces por mes');
      final sections = api.lastDocumentContent!['sections'] as List;
      expect((sections.first as Map)['items'], [
        'Temporada alta ([MESES_TEMPORADA_ALTA]): [SERVICIO_MANTENIMIENTO], [DIAS_TEMPORADA_ALTA]',
        'Temporada baja ([MESES_TEMPORADA_BAJA]): [SERVICIO_MANTENIMIENTO], [FRECUENCIA_TEMPORADA_BAJA]',
      ]);
      expect((sections[1] as Map)['items'],
          ['Una visita especial acordada con el cliente.']);
      expect((sections[2] as Map)['items'], isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MaterialApp(
          home: PresupuestoTemplateEditorScreen(
        api: api,
        groupId: 'group-1',
        presupuestoId: 'draft-1',
      )));
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      await tester.tap(find.text('Previsualizar'));
      await tester.pumpAndSettle();
      expect(api.previewVariables, variables);
      await tester.tap(find.text('Descargar PDF'));
      await tester.pumpAndSettle();
      expect(api.downloadVariables, variables);
      expect(api.lastDocumentContent!['sections'], sections);
    });
  }

  testWidgets(
      'generated frequency follows chips and preserves manual additions',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _SeasonDocumentApi(generatedFrequency: true);
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      createDocumentDraft: true,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar plantilla').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
        const ValueKey('service_mantenimiento del jardín y la piscina')));
    for (final month in [5, 5]) {
      final chip = find.byKey(ValueKey('high_season_month_$month'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    await tester.enterText(
        find.byKey(const ValueKey('high_season_frequency')), '4 veces por mes');
    await tester.enterText(
        find.byKey(const ValueKey('low_season_frequency')), '2 veces por mes');
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
    await tester.pumpAndSettle();
    expect(find.text('Generado automáticamente'), findsOneWidget);
    expect(
        find.textContaining(
            'junio, julio, agosto y septiembre, el servicio de mantenimiento del jardín y la piscina'),
        findsWidgets);
    expect(find.byKey(const ValueKey('work_frequency_item_field_0')),
        findsNothing);
    await tester.tap(find.text('Añadir elemento'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('work_frequency_item_field_0')),
        'Revisar el riego.');
    await tester.tap(find.text('Editar servicio y frecuencias'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('service_mantenimiento del jardín')));
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('work_frequency_item_field_0')))
            .controller!
            .text,
        'Revisar el riego.');
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar borrador'));
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    final section =
        (api.lastDocumentContent!['sections'] as List).single as Map;
    expect(section['generatedFrequency'], true);
    expect(section['items'], ['Revisar el riego.']);
    final variables = api.lastDocumentContent!['variables'] as Map;
    expect(variables['SERVICIO_MANTENIMIENTO'], 'mantenimiento del jardín');
    expect(variables['MESES_TEMPORADA_BAJA'],
        'Ene, Feb, Mar, Abr, May, Oct, Nov, Dic');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(
        home: PresupuestoTemplateEditorScreen(
      api: api,
      groupId: 'group-1',
      presupuestoId: 'draft-1',
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
    await tester.pumpAndSettle();
    expect(find.text('Generado automáticamente'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('work_frequency_item_field_0')))
            .controller!
            .text,
        'Revisar el riego.');
    expect(find.textContaining('frecuencia de 4 veces por mes.'), findsWidgets);
    expect(find.textContaining('frecuencia de 2 veces por mes.'), findsWidgets);
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

    expect(find.byKey(const ValueKey('editor_step_Imagenes')), findsOne);
    expect(find.text('0/6 imagenes'), findsOne);
    expect(api.defaultDocumentCreates, 0);
  });

  testWidgets('saved library image can be attached to a budget slot',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2200);
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
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
    await tester.pumpAndSettle();
    final service =
        find.byKey(const ValueKey('service_limpieza de la piscina'));
    await tester.ensureVisible(service);
    await tester.pumpAndSettle();
    await tester.tap(service);
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor_step_Imagenes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar de la biblioteca').first);
    await tester.pumpAndSettle();

    expect(find.text('Choose from image library'), findsOneWidget);
    await tester.tap(find.text('Piscina principal'));
    await tester.pumpAndSettle();

    expect(api.attachedTargetId, 'draft-1');
    expect(api.attachedImageId, 'library-image-1');
    expect(api.attachedSlot, 'photo_1');
    expect(find.text('1/6 imagenes'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('variable_FRECUENCIA_MENSUAL')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('variable_PRECIO_VISITA')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('variable_PRECIO_HORA')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('variable_CLIENTE')))
          .controller!
          .text,
      'Comunidad Limpia',
    );
  });

  testWidgets(
      'existing document renders every returned variable and patches edits',
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

    expect(
      find.byKey(const ValueKey('variable_PRECIO_HORA')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('variable_PRECIO_PISCINA_PRIVADA')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('variable_PRECIO_VISITA')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('variable_PRODUCTOS_INCLUIDOS')),
      findsOneWidget,
    );
    expect(find.text('Año: '), findsOneWidget);
    expect(find.text('Servicios y mantenimiento'), findsOneWidget);
    expect(find.text('Precios adicionales'), findsOneWidget);
    expect(find.text('Condiciones del contrato'), findsOneWidget);
    expect(find.textContaining('[ZONAS_COMUNES]'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('variable_PRECIO_HORA')))
          .keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(
      tester
          .widget<TextField>(
              find.byKey(const ValueKey('variable_ZONAS_COMUNES')))
          .maxLines,
      3,
    );
    await tester.enterText(
      find.byKey(const ValueKey('variable_PRECIO_VISITA')),
      '500 €',
    );
    await tester.enterText(
      find.byKey(const ValueKey('variable_ZONAS_COMUNES')),
      'portal, piscina y jardines',
    );
    await tester.enterText(
      find.byKey(const ValueKey('variable_PRODUCTOS_INCLUIDOS')),
      'con productos incluidos',
    );
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();

    expect(api.updatedVariables, <String, dynamic>{
      'PRECIO_VISITA': '500 €',
      'ZONAS_COMUNES': 'portal, piscina y jardines',
      'PRODUCTOS_INCLUIDOS': 'con productos incluidos',
    });
    expect(api.templateVariableLoads, 2);
    expect(api.updatedVariables, isNot(contains('MES')));
    expect(
      (api.savedContent!['variableFields'] as List)
          .whereType<Map>()
          .map((field) => field['key'])
          .contains('PRECIO_HORA'),
      isFalse,
    );
  });

  testWidgets('unused manual monthly total remains editable', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: _UnusedMonthlyTotalApi(),
          groupId: 'group-1',
          presupuestoId: 'budget-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byKey(const ValueKey('variable_TOTAL_MENSUAL'));
    expect(tester.widget<TextField>(finder).enabled, isTrue);
    expect(find.text('Importe mensual (opcional)'), findsOneWidget);
    for (final key in const <String>[
      'IMPORTE_MENSUAL',
      'FRECUENCIA_MENSUAL',
      'PRECIO_VISITA',
    ]) {
      expect(find.byKey(ValueKey('variable_$key')), findsNothing);
    }

    await tester.enterText(finder, '1.920 €');
    await tester.pump();

    expect(tester.widget<TextField>(finder).controller!.text, '1.920 €');
  });

  testWidgets(
      'automatic monthly amount without a formula can be edited and saved',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _UnusedMonthlyTotalApi(automaticMonthlyTotal: true);
    await tester.pumpWidget(MaterialApp(
      home: PresupuestoTemplateEditorScreen(
        api: api,
        groupId: 'group-1',
        presupuestoId: 'budget-1',
      ),
    ));
    await tester.pumpAndSettle();

    final amount = find.byKey(const ValueKey('variable_TOTAL_MENSUAL'));
    expect(tester.widget<TextField>(amount).enabled, isTrue);
    await tester.enterText(amount, '1.920,50 €');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();

    expect(api.updatedVariables, {'TOTAL_MENSUAL': '1.920,50 €'});
    expect(
        (api.savedContent!['variables'] as Map)['TOTAL_MENSUAL'], '1.920,50 €');
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(amount).controller!.text, '1.920,50 €');
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview warns when the backend reports unresolved variables',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PresupuestoTemplateEditorScreen(
          api: _UnresolvedDocumentApi(),
          groupId: 'group-1',
          presupuestoId: 'budget-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Previsualizar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Variables sin completar'), findsOneWidget);
    expect(
      find.textContaining(
        'Todavía quedan variables sin valor: [ZONAS_COMUNES], [PRODUCTOS_INCLUIDOS]',
      ),
      findsOneWidget,
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
    await tester.tap(find.byKey(const ValueKey('editor_step_Datos')));
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
    await tester.tap(find.byKey(const ValueKey('editor_step_Secciones')));
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
  _FakePresupuestosApi(
      {this.omitTableCalculations = false, this.generatedFrequency = false});

  final bool generatedFrequency;

  final bool omitTableCalculations;
  int defaultDocumentCreates = 0;
  String? lastDefaultKey;
  Map<String, dynamic>? lastDocumentContent;
  String? attachedTargetId;
  String? attachedImageId;
  String? attachedSlot;

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
            'SERVICIO_MANTENIMIENTO',
            'FRECUENCIA_TEMPORADA_BAJA',
            'IMPORTE_MENSUAL',
            'DURACION_CONTRATO',
            'PREAVISO',
          ]),
          'sections': <Map<String, dynamic>>[
            if (generatedFrequency)
              {
                'key': 'work_frequency',
                'order': 3,
                'title': 'Frecuencia de trabajos.',
                'generatedFrequency': true,
                'items': <String>[],
              },
          ],
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

  @override
  Future<Map<String, dynamic>> getTemplateVariables(
    String presupuestoId,
  ) async {
    return <String, dynamic>{
      'variables': lastDocumentContent?['variables'] ?? <String, dynamic>{},
      'variableFields':
          lastDocumentContent?['variableFields'] ?? <Map<String, dynamic>>[],
      'unresolvedKeys': <String>[],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> listImageLibrary(String groupId) async {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        '_id': 'library-image-1',
        'name': 'Piscina principal',
        'readUrl': 'https://example.test/piscina.jpg',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> attachImageLibraryAsset({
    required String targetId,
    required String imageId,
    required String slot,
    String? label,
    bool enabled = true,
  }) async {
    attachedTargetId = targetId;
    attachedImageId = imageId;
    attachedSlot = slot;
    return <String, dynamic>{
      'image': <String, dynamic>{
        'slot': slot,
        'readUrl': 'https://example.test/piscina.jpg',
        'label': label,
        'enabled': enabled,
      },
    };
  }
}

class _ExistingDocumentApi extends PresupuestosApi {
  Map<String, dynamic>? updatedVariables;
  Map<String, dynamic>? savedContent;
  int templateVariableLoads = 0;

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
    templateVariableLoads++;
    return <String, dynamic>{
      'variables': <String, dynamic>{
        'CLIENTE': 'Comunidad Reabierta',
        'PRECIO_VISITA': '480 €',
        'PRECIO_HORA': '25 €',
        'FECHA': '',
        'DIA': '',
        'MES': '',
        'ANO': '',
        'AÑO': '',
        'ZONAS_COMUNES': '',
        'PRODUCTOS_INCLUIDOS': '',
      },
      'variableFields': <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'CLIENTE',
          'label': 'CLIENTE',
          'value': 'Comunidad Reabierta',
        },
        for (final key in const <String>['FECHA', 'DIA', 'MES', 'ANO', 'AÑO'])
          <String, dynamic>{
            'key': key,
            'label': key,
            'value': '',
            'isAutomatic': true,
            'readOnly': true,
          },
        ..._fields(<String>['DURACION_CONTRATO', 'ZONAS_COMUNES']),
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

class _UnusedMonthlyTotalApi extends _ExistingDocumentApi {
  _UnusedMonthlyTotalApi({this.automaticMonthlyTotal = false});

  final bool automaticMonthlyTotal;

  @override
  Future<Map<String, dynamic>> getTemplateVariables(
    String presupuestoId,
  ) async {
    return <String, dynamic>{
      'variables': <String, dynamic>{
        'CLIENTE': 'Comunidad Las Alondras',
        'TOTAL_MENSUAL': '',
        'IMPORTE_MENSUAL': '',
        'FRECUENCIA_MENSUAL': '',
        'PRECIO_VISITA': '',
      },
      'variableFields': <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'CLIENTE',
          'label': 'CLIENTE',
          'value': 'Comunidad Las Alondras',
        },
        <String, dynamic>{
          'key': 'TOTAL_MENSUAL',
          'label': 'TOTAL_MENSUAL',
          'value': updatedVariables?['TOTAL_MENSUAL'] ?? '',
          'isAutomatic': automaticMonthlyTotal,
          'isUsedInTemplate': false,
        },
        <String, dynamic>{
          'key': 'IMPORTE_MENSUAL',
          'label': 'IMPORTE_MENSUAL',
          'value': '',
          'isAutomatic': true,
        },
        for (final key in const <String>[
          'FRECUENCIA_MENSUAL',
          'PRECIO_VISITA',
        ])
          <String, dynamic>{
            'key': key,
            'label': key,
            'value': '',
            'isUsedInTemplate': false,
          },
      ],
    };
  }
}

class _AutomaticClientApi extends _UnusedMonthlyTotalApi {
  @override
  Future<Map<String, dynamic>> getTemplateVariables(
      String presupuestoId) async {
    final response = await super.getTemplateVariables(presupuestoId);
    for (final field in response['variableFields'] as List) {
      if (field['key'] == 'CLIENTE') {
        field['isAutomatic'] = true;
        field['value'] = updatedVariables?['CLIENTE'] ?? field['value'];
      }
    }
    return response;
  }
}

class _UnresolvedDocumentApi extends _ExistingDocumentApi {
  @override
  Future<Map<String, dynamic>> getTemplateVariables(
    String presupuestoId,
  ) async {
    final payload = await super.getTemplateVariables(presupuestoId);
    return <String, dynamic>{
      ...payload,
      'unresolvedKeys': <String>[
        'ZONAS_COMUNES',
        'PRODUCTOS_INCLUIDOS',
      ],
    };
  }
}

List<Map<String, dynamic>> _fields(List<String> keys) => keys
    .map((key) => <String, dynamic>{'key': key, 'label': key})
    .toList(growable: false);

class _SeasonDocumentApi extends _FakePresupuestosApi {
  _SeasonDocumentApi({super.generatedFrequency});
  @override
  Future<Map<String, dynamic>> getTemplateContent(String presupuestoId) async =>
      {
        'content': lastDocumentContent,
      };
}

class _ServiceDocumentApi extends _SeasonDocumentApi {
  Map<String, dynamic>? updatedVariables;

  @override
  Future<Map<String, dynamic>> updateTemplateVariables(String presupuestoId,
      {required Map<String, dynamic> variables, String? reason}) async {
    updatedVariables = variables;
    lastDocumentContent!['variables'] = {
      ...lastDocumentContent!['variables'] as Map,
      ...variables,
    };
    return {'presupuestoId': presupuestoId};
  }

  Map? previewVariables;
  Map? downloadVariables;

  @override
  Future<http.Response> previewTemplatePdf(String id) async {
    previewVariables = Map.of(lastDocumentContent!['variables'] as Map);
    throw Exception('PDF endpoint reached');
  }

  @override
  Future<http.Response> downloadTemplatePdf(String id) async {
    downloadVariables = Map.of(lastDocumentContent!['variables'] as Map);
    throw Exception('PDF endpoint reached');
  }

  _ServiceDocumentApi(String service) {
    content = {
      'key': 'garden_pool_annual_maintenance',
      'name': 'Mantenimiento',
      'variables': {
        'SERVICIO_MANTENIMIENTO': service,
        'MESES_TEMPORADA_ALTA': 'Junio a septiembre',
        'MESES_TEMPORADA_BAJA': 'Resto del año',
        'DIAS_TEMPORADA_ALTA': '4 veces por mes',
        'FRECUENCIA_TEMPORADA_BAJA': '2 veces por mes',
        'IMPORTE_MENSUAL': '300',
      },
      'variableFields': _fields([
        'SERVICIO_MANTENIMIENTO',
        'MESES_TEMPORADA_ALTA',
        'MESES_TEMPORADA_BAJA',
        'DIAS_TEMPORADA_ALTA',
        'FRECUENCIA_TEMPORADA_BAJA',
        'IMPORTE_MENSUAL',
      ]),
      'sections': [
        {
          'key': 'frequency',
          'order': 1,
          'enabled': true,
          'title': 'Frecuencia de trabajos',
          'body': 'Texto editado manualmente',
          'items': ['Una visita especial acordada con el cliente.']
        },
        {
          'key': 'deleted_items',
          'order': 2,
          'enabled': false,
          'title': 'Otra sección',
          'body': '',
          'items': <String>[]
        },
      ],
      'totals': {'total': 300, 'currency': 'EUR'},
      'images': <Map<String, dynamic>>[],
    };
    lastDocumentContent = content;
    // Saved values must win over a stale schema default.
    ((content['variableFields'] as List).first as Map)['value'] =
        'limpieza de la piscina';
  }
  late final Map<String, dynamic> content;

  @override
  Future<Map<String, dynamic>> listDefaultTemplates() async => {
        'templates': [content]
      };

  @override
  Future<Map<String, dynamic>> saveTemplateContent(
      String presupuestoId, Map<String, dynamic> payload) async {
    lastDocumentContent = payload;
    return {'presupuestoId': presupuestoId};
  }
}
