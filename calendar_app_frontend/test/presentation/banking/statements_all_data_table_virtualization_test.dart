import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/table/statements_all_data_table.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/table/statements_all_data_table_row.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/table/statements_all_data_table_theme.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_link_button.dart';

void main() {
  for (final layout in [
    (1188.0, 1188.0),
    (1920.0, 844.0),
    (1920.0, 1099.0),
    (1920.0, 1100.0),
    (390.0, 390.0)
  ]) {
    testWidgets(
        'movements table virtualizes rows with window/table widths $layout',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(layout.$1, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final suggested = <String>[];
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
                builder: (context) => Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                        width: layout.$2,
                        child: StatementsAllDataTable(
                          entries: entries,
                          controller: controller,
                          selectedIds: const {},
                          onToggleAll: (_) {},
                          onToggleRow: (_) {},
                          onShowDetails: (_) {},
                          onSuggest: (entry) =>
                              suggested.add(entry['_id'] as String),
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
                          onDescriptionFilterTap: () {},
                          descriptionFilterActive: false,
                          onNotesFilterTap: () {},
                          notesFilterActive: false,
                          onClientProviderFilterTap: () {},
                          clientProviderFilterActive: false,
                          onInvoiceSortTap: () {},
                          invoiceSortMode: 0,
                        ))),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(StatementsAllDataTableRow).evaluate().length,
          lessThan(25));
      expect(find.text('Transf. a su favor'), findsOneWidget);
      expect(find.text('Lote'), findsNothing);
      expect(find.text('Saldo'), findsNothing);
      expect(find.text('Notas'), findsNothing);
      expect(find.text('Contacto'),
          layout.$2 >= 1100 ? findsOneWidget : findsNothing);
      // The "Vincular" action now lives inside the row's 3-dot menu.
      expect(find.byType(HexoraLinkButton), findsNothing);
      final moreActions = find.byTooltip('Más acciones');
      expect(moreActions, findsWidgets);
      await tester.ensureVisible(moreActions.first);
      await tester.pumpAndSettle();
      await tester.tap(moreActions.first);
      await tester.pumpAndSettle();
      expect(find.text('Vincular'), findsOneWidget);
      expect(find.text('Vincular cliente'), findsNothing);
      expect(find.text('Añadir nota'), findsOneWidget);
      expect(find.textContaining('manualmente'), findsNothing);
      final firstMenuItem = find
          .byWidgetPredicate((widget) => widget is PopupMenuItem<String>)
          .first;
      expect(tester.getSize(firstMenuItem).width, greaterThanOrEqualTo(112));
      await tester.tap(find.text('Vincular'));
      await tester.pumpAndSettle();
      expect(suggested, ['entry-0']);
      expect(tester.takeException(), isNull);
      final dateLabels = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText());
      expect(dateLabels, contains('Op. 1/8/2026\nVal. 3/8/2026'));
    });
  }
}
