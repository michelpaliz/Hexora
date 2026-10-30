import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/group_invoices_invoices_view.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('consolidates invoice toolbar actions and preserves handlers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var recentTaps = 0;
    var refreshTaps = 0;
    Set<HexoraFinancialColumn>? selectedColumns;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: InvoiceToolbarOptionsMenu(
              count: 4,
              downloading: false,
              availableColumns: const {
                HexoraFinancialColumn.date,
                HexoraFinancialColumn.concept,
                HexoraFinancialColumn.total,
              },
              visibleColumns: const {
                HexoraFinancialColumn.date,
                HexoraFinancialColumn.total,
              },
              onColumnsChanged: (value) => selectedColumns = value,
              unlinkedOnly: false,
              paymentSuggestionsLoading: false,
              toolbarOptions: InvoiceToolbarOptions(
                onOpenRecentExports: () => recentTaps++,
                recentExportsCount: 7,
                onRefresh: () => refreshTaps++,
              ),
              onPdf: () {},
              onExcel: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Recent exports'), findsNothing);

    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();

    expect(find.text('Recent exports'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Columns'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(refreshTaps, 1);

    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recent exports'));
    await tester.pumpAndSettle();
    expect(recentTaps, 1);

    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();
    expect(find.text('Concept'), findsOneWidget);
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();

    expect(selectedColumns, {HexoraFinancialColumn.total});
    expect(tester.takeException(), isNull);
  });
}
