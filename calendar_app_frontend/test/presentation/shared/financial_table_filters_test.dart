import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';

void main() {
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
}
