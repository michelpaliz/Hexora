import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/client_filter_controls.dart';

void main() {
  for (final width in [320.0, 1200.0]) {
    for (final dark in [false, true]) {
      testWidgets('filters at $width dark=$dark preserve collapsed selections',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final search = TextEditingController();
        addTearDown(search.dispose);
        String? entity;
        var status = 'all';
        var hidden = false;
        var invoice = false;
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: StatefulBuilder(
                      builder: (context, setState) => ClientsSearchFilters(
                            searchController: search,
                            onSearchChanged: () => setState(() {}),
                            searchHint: 'Buscar clientes...',
                            activeCount: 34,
                            inactiveCount: 8,
                            activeCountLabel: 'Activos',
                            inactiveCountLabel: 'Inactivos',
                            statusValue: status,
                            onStatusChanged: (value) =>
                                setState(() => status = value),
                            inactiveValue: hidden,
                            inactiveValueMeansHidden: true,
                            inactiveLabelOn: 'Ocultar',
                            inactiveLabelOff: 'Mostrar',
                            onInactiveChanged: (value) =>
                                setState(() => hidden = value),
                            entityLabel: 'Tipo de entidad',
                            entityOptions: const ['Comunidad de propietarios'],
                            entityFilter: entity,
                            onToggleEntity: (value) =>
                                setState(() => entity = value),
                            onClearEntity: () => setState(() => entity = null),
                            propertyLabel: 'Tipo de propiedad',
                            propertyOptions: const ['Vivienda'],
                            onToggleProperty: (_) {},
                            onClearProperty: () {},
                            additionalFilters: ClientMissingInvoiceFilter(
                                count: 41,
                                selected: invoice,
                                onTap: () =>
                                    setState(() => invoice = !invoice)),
                          )))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(TextField)).width,
          lessThanOrEqualTo(width >= 760 ? 450 : width),
        );
        expect(find.byType(DropdownButton<String>), findsNothing);
        await tester.enterText(find.byType(TextField), 'Mar');
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(hidden, isTrue);
        await tester.tap(
            find.byKey(const ValueKey('client-missing-month-invoice-filter')));
        await tester.pumpAndSettle();
        expect(invoice, isTrue);
        final toggle =
            find.byKey(const ValueKey('client-advanced-filters-toggle'));
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButton<String>), findsNWidgets(2));
        await tester
            .tap(find.byKey(const ValueKey('client-filter-Tipo de entidad')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Comunidad de propietarios').last);
        await tester.pumpAndSettle();
        expect(entity, 'Comunidad de propietarios');
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButton<String>), findsNothing);
        expect(search.text, 'Mar');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
