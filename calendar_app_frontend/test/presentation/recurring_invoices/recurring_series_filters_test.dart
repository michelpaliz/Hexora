import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_filters.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
        'recurring toolbar is compact and filters remain reactive in $brightness',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final search = TextEditingController();
      addTearDown(search.dispose);
      var status = 'Activas';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forPlatform(brightness,
              platform: TargetPlatform.windows),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RecurringSeriesFilters(
                searchController: search,
                onSearchChanged: () => setState(() {}),
                activeFilterCount: status == 'Todos' ? 0 : 1,
                statusOptions: const ['Todos', 'Activas', 'Inactivas'],
                selectedStatus: status,
                onStatusSelected: (value) => setState(() => status = value),
                onStatusClear: () => setState(() => status = 'Todos'),
                clientOptions: const ['Alqueria', 'Belman'],
                selectedClient: null,
                onClientSelected: (_) {},
                onClientClear: () {},
                frequencyOptions: const ['monthly'],
                selectedFrequency: null,
                onFrequencySelected: (_) {},
                onFrequencyClear: () {},
                dueSoonOnly: false,
                onDueSoonChanged: (_) {},
                showInactiveClients: false,
                onShowInactiveChanged: (_) {},
                sortByClientName: true,
                onSortByClientNameChanged: (_) {},
                onClearFilters: () => setState(() => status = 'Todos'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchFinder =
          find.byKey(const ValueKey('recurring-series-search'));
      final filterFinder =
          find.byKey(const ValueKey('recurring-series-filters-button'));
      expect(tester.getSize(searchFinder).width, 320);
      expect(tester.getSize(searchFinder).height, 38);
      expect(tester.getCenter(filterFinder).dy,
          closeTo(tester.getCenter(searchFinder).dy, 1));
      expect(find.byType(InputChip), findsNothing);
      expect(
        find.byKey(const ValueKey('recurring-series-clear-filters')),
        findsOneWidget,
      );

      await tester.tap(filterFinder);
      await tester.pumpAndSettle();
      expect(find.text('Inactivas'), findsOneWidget);
      await tester.tap(find.text('Inactivas'));
      await tester.pumpAndSettle();
      expect(status, 'Inactivas');

      await tester.tap(filterFinder);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('recurring-series-clear-filters')),
      );
      await tester.pumpAndSettle();
      expect(status, 'Todos');
      expect(find.byType(InputChip), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
