import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/table/statements_all_data_table.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/table/statements_all_data_table_theme.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('the row open in the side panel is highlighted, others are not',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = StatementsController(useAggregated: false);
    addTearDown(controller.dispose);
    final entries = List.generate(
      3,
      (index) => <String, dynamic>{
        '_id': 'entry-$index',
        'date': '2026-08-01',
        'description': 'Movement $index',
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
          body: Builder(
            builder: (context) => StatementsAllDataTable(
              entries: entries,
              controller: controller,
              selectedIds: const {},
              activeEntryId: 'entry-1',
              onToggleAll: (_) {},
              onToggleRow: (_) {},
              onShowDetails: (_) {},
              onSuggest: (_) {},
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
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Color rowColorFor(String text) {
      final material = tester.widget<Material>(
        find
            .ancestor(of: find.text(text), matching: find.byType(Material))
            .first,
      );
      return material.color!;
    }

    final tableTheme = StatementsTableTheme.light(
      Theme.of(tester.element(find.byType(StatementsAllDataTable))).colorScheme,
    );
    expect(rowColorFor('Movement 1'), tableTheme.rowActive);
    expect(rowColorFor('Movement 0'), isNot(tableTheme.rowActive));
    expect(rowColorFor('Movement 2'), isNot(tableTheme.rowActive));
  });
}
