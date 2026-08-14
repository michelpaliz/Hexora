import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/all_data/table/statements_all_data_table.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/all_data/table/statements_all_data_table_row.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/all_data/table/statements_all_data_table_theme.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets('movements table virtualizes rows in an unbounded page',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1188, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = StatementsController(useAggregated: false);
    addTearDown(controller.dispose);
    final entries = List.generate(
      200,
      (index) => <String, dynamic>{
        '_id': 'entry-$index',
        'date': '2026-08-01',
        if (index == 0) 'valueDate': '2026-08-03',
        'description': index == 0 ? 'TRANSF. A SU FAVOR' : 'Movement $index',
        'amount': '10.00',
        'balance': '100.00',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) => StatementsAllDataTable(
                entries: entries,
                controller: controller,
                selectedIds: const {},
                onToggleAll: (_) {},
                onToggleRow: (_) {},
                onShowDetails: (_) {},
                onSuggest: (_) {},
                onLink: (_) {},
                onLinkInvoice: (_) {},
                onMarkNoProcede: (_) {},
                noProcedeReasonForEntry: (_) => null,
                tableTheme: StatementsTableTheme.light(
                  Theme.of(context).colorScheme,
                ),
                onAmountFilterTap: () {},
                amountFilterActive: false,
                onDateFilterTap: () {},
                dateFilterActive: false,
                onClientProviderFilterTap: () {},
                clientProviderFilterActive: false,
                onInvoiceSortTap: () {},
                invoiceSortMode: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
        find.byType(StatementsAllDataTableRow).evaluate().length, lessThan(25));
    expect(find.text('Transf. a su favor'), findsOneWidget);
    expect(find.text('Lote'), findsNothing);
    expect(find.text('Saldo'), findsNothing);
    expect(find.text('Notas'), findsNothing);
    expect(find.text('Contacto'), findsOneWidget);
    expect(find.byTooltip('Más acciones'), findsWidgets);
    await tester.tap(find.byTooltip('Más acciones').first);
    await tester.pumpAndSettle();
    expect(find.text('Vincular cliente'), findsOneWidget);
    expect(find.text('Añadir nota'), findsOneWidget);
    final firstMenuItem = find
        .byWidgetPredicate((widget) => widget is PopupMenuItem<String>)
        .first;
    expect(tester.getSize(firstMenuItem).width, greaterThanOrEqualTo(112));
    expect(tester.takeException(), isNull);
    final dateLabels = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((widget) => widget.text.toPlainText());
    expect(dateLabels, contains('Op. 1/8/2026\nVal. 3/8/2026'));
  });
}
