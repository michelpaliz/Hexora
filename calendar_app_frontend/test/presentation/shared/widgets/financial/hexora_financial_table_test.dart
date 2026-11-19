import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  test('formats positive, negative and empty monetary values in Spanish', () {
    expect(HexoraFinancialFormat.money(1234.56), '1.234,56 €');
    expect(HexoraFinancialFormat.money(-42.5), '-42,50 €');
    expect(HexoraFinancialFormat.money(null), '—');
  });

  test('formats compact Spanish dates', () {
    expect(
      HexoraFinancialFormat.date(DateTime(2026, 9, 26)),
      '26 sept 2026',
    );
  });

  testWidgets('column menu toggles and persists a module preference',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var visible = <HexoraFinancialColumn>{
      HexoraFinancialColumn.date,
      HexoraFinancialColumn.total,
    };

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        return Scaffold(
          body: HexoraColumnVisibilityMenu(
            moduleKey: 'test-module',
            availableColumns: const {
              HexoraFinancialColumn.date,
              HexoraFinancialColumn.total,
            },
            visibleColumns: visible,
            onChanged: (value) => setState(() => visible = value),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Columnas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fecha'));
    await tester.pumpAndSettle();

    expect(visible, isNot(contains(HexoraFinancialColumn.date)));
    expect(
      await HexoraColumnVisibilityStore.load(
        'test-module',
        const {HexoraFinancialColumn.date},
      ),
      {HexoraFinancialColumn.total},
    );
  });
}
