import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';

void main() {
  testWidgets('desktop date range picker is constrained to a compact surface',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => hexoraCompactDateRangePickerBuilder(
          context,
          const SizedBox(
            key: ValueKey('date-range-picker-content'),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    ));

    expect(
      tester.getSize(find.byKey(const ValueKey('date-range-picker-content'))),
      const Size(520, 620),
    );
  });

  testWidgets('multi-select filters preserve simultaneous selections',
      (tester) async {
    Set<String> selected = {};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HexoraMultiSelectFilter(
          values: const ['Arjen', 'Cindy'],
          selected: const {},
          labelFor: (value) => value,
          onChanged: (value) => selected = value,
        ),
      ),
    ));

    await tester.tap(find.text('Arjen'));
    await tester.pump();
    await tester.tap(find.text('Cindy'));
    await tester.pump();

    expect(selected, {'Arjen', 'Cindy'});
  });

  testWidgets(
      'searchable multi-select ignores accents and preserves hidden selections',
      (tester) async {
    Set<String> selected = {};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: HexoraMultiSelectFilter(
            values: const ['Álvaro Gestión', 'Comunidad Sol'],
            selected: const {},
            labelFor: (value) => value,
            onChanged: (value) => selected = value,
            searchable: true,
            searchHint: 'Buscar cliente...',
            emptyLabel: 'No se encontraron clientes',
            selectionSingularLabel: 'cliente seleccionado',
            selectionPluralLabel: 'clientes seleccionados',
          ),
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'alvaro');
    await tester.pump();
    expect(find.text('Álvaro Gestión'), findsOneWidget);
    expect(find.text('Comunidad Sol'), findsNothing);

    await tester.tap(find.text('Álvaro Gestión'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'sin coincidencias');
    await tester.pump();

    expect(selected, {'Álvaro Gestión'});
    expect(find.text('1 cliente seleccionado'), findsOneWidget);
    expect(find.text('No se encontraron clientes'), findsOneWidget);
  });

  testWidgets('amount range accepts Spanish decimal formatting',
      (tester) async {
    num? minimum;
    num? maximum;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: HexoraAmountRangeInput(
            onChanged: (min, max) {
              minimum = min;
              maximum = max;
            },
          ),
        ),
      ),
    ));

    await tester.enterText(find.byType(TextFormField).first, '1.234,56');
    await tester.enterText(find.byType(TextFormField).last, '2.000,00');

    expect(minimum, 1234.56);
    expect(maximum, 2000);
  });

  testWidgets('filter header exposes sorting and active state', (tester) async {
    var ascending = false;
    var cleared = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HexoraFilterableHeaderCell(
          label: 'Total',
          width: 140,
          filterActive: true,
          menuBuilder: (_) => HexoraColumnFilterMenu(
            label: 'Total',
            onSortAscending: () => ascending = true,
            onSortDescending: () {},
            filterActive: true,
            onClear: () => cleared = true,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    ));

    await tester.tap(find.byTooltip('Filtrar y ordenar Total'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ascendente'));
    await tester.pumpAndSettle();

    expect(ascending, isTrue);
    expect(find.text('Limpiar'), findsOneWidget);

    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
    expect(find.text('Limpiar'), findsNothing);
    expect(find.byTooltip('Filtrar y ordenar Total'), findsOneWidget);
  });

  testWidgets('filter header lays out and opens in a narrow table column',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HexoraFilterableHeaderCell(
                label: 'Base imponible',
                width: 92,
                menuBuilder: (_) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Filtro compacto'),
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Filtrar y ordenar Base imponible'));
    await tester.pumpAndSettle();

    expect(find.text('Filtro compacto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open filter survives responsive header removal', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 560
              ? HexoraFilterableHeaderCell(
                  label: 'Cliente',
                  width: 180,
                  menuBuilder: (_) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Filtro adaptable'),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    ));

    await tester.tap(find.byTooltip('Filtrar y ordenar Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Filtro adaptable'), findsOneWidget);

    tester.view.physicalSize = const Size(480, 640);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(450, 600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('filter surface supports a scrollable value list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HexoraFilterableHeaderCell(
          label: 'Cliente',
          width: 180,
          menuBuilder: (_) => Padding(
            padding: const EdgeInsets.all(12),
            child: HexoraMultiSelectFilter(
              values: List.generate(40, (index) => 'Cliente $index'),
              selected: const {},
              labelFor: (value) => value,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.byTooltip('Filtrar y ordenar Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente 0'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
