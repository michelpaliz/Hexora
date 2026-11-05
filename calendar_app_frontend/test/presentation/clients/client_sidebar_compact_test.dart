import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/clients_list_panel.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('customer sidebar keeps controls and filters compact',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final search = TextEditingController();
    addTearDown(search.dispose);
    final clients = <GroupClient>[
      GroupClient(
        id: 'active-community',
        name: 'Alqueria',
        email: 'a@example.com',
        customerType: 'community',
        propertyType: 'building',
        missingCurrentMonthInvoice: true,
      ),
      GroupClient(
        id: 'active-company',
        name: 'Belman',
        email: 'b@example.com',
        customerType: 'company',
        propertyType: 'commercial_premises',
        missingCurrentMonthInvoice: false,
      ),
      GroupClient(
        id: 'inactive-company',
        name: 'Brisas',
        email: 'c@example.com',
        customerType: 'company',
        propertyType: 'building',
        isActive: false,
        missingCurrentMonthInvoice: true,
      ),
    ];

    var hideInactive = true;
    var missingOnly = false;
    String? entityFilter;
    String? propertyFilter;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              final filtered = clients.where((client) {
                if (hideInactive && !client.isActive) return false;
                if (missingOnly && client.missingCurrentMonthInvoice != true) {
                  return false;
                }
                if (entityFilter != null &&
                    client.effectiveCustomerType != entityFilter) {
                  return false;
                }
                if (propertyFilter != null &&
                    client.effectivePropertyType != propertyFilter) {
                  return false;
                }
                return true;
              }).toList();
              return ClientsListPanel(
                allClients: clients,
                filteredClients: filtered,
                selectedClient: clients.first,
                selectedHiddenByFilters: false,
                hideInactive: hideInactive,
                onToggleHideInactive: () =>
                    setState(() => hideInactive = !hideInactive),
                missingCurrentMonthInvoiceOnly: missingOnly,
                onToggleMissingCurrentMonthInvoiceOnly: (value) =>
                    setState(() => missingOnly = value),
                searchController: search,
                onSearchChanged: () => setState(() {}),
                entityFilter: entityFilter,
                propertyFilter: propertyFilter,
                entityOptions: const ['community', 'company'],
                propertyOptions: const ['building', 'commercial_premises'],
                onClearFilters: () => setState(() {
                  entityFilter = null;
                  propertyFilter = null;
                  missingOnly = false;
                }),
                onToggleEntityFilter: (value) =>
                    setState(() => entityFilter = value),
                onTogglePropertyFilter: (value) =>
                    setState(() => propertyFilter = value),
                onClearEntityFilter: () => setState(() => entityFilter = null),
                onClearPropertyFilter: () =>
                    setState(() => propertyFilter = null),
                onSelectClient: (_) {},
                onRefresh: () {},
                onAddClient: () {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    final filterButton =
        find.byKey(const ValueKey('client-advanced-filters-toggle'));
    expect(tester.getSize(searchField).height, lessThanOrEqualTo(34));
    expect(tester.getSize(filterButton).height, lessThanOrEqualTo(34));
    expect(find.byKey(const ValueKey('client-sidebar-refresh')), findsNothing);
    expect(find.byKey(const ValueKey('client-sidebar-add')), findsNothing);
    expect(find.byKey(const ValueKey('client-sidebar-sort')), findsNothing);
    expect(
      tester.getTopLeft(filterButton).dx,
      lessThan(tester.getTopLeft(searchField).dx),
    );
    expect(find.byTooltip('Filtros (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey('client-sidebar-list-summary')),
        findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('client-sidebar-list-summary')))
          .height,
      30,
    );
    expect(
      tester
          .getSize(
              find.byKey(const ValueKey('client-sidebar-row-active-community')))
          .height,
      lessThanOrEqualTo(48),
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('client-filter-popover')), findsOneWidget);
    expect(find.byKey(const ValueKey('client-sidebar-status-all')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('client-sidebar-status-active')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('client-sidebar-status-inactive')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('client-filter-select-Tipo de cliente')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('client-filter-select-Tipo de inmueble')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('client-missing-month-invoice-filter')),
        findsOneWidget);
    expect(
      tester
          .getSize(
              find.byKey(const ValueKey('client-missing-month-invoice-filter')))
          .height,
      lessThanOrEqualTo(28),
    );

    await tester
        .tap(find.byKey(const ValueKey('client-missing-month-invoice-filter')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Filtros (2)'), findsOneWidget);

    await tester.tapAt(const Offset(410, 710));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('client-filter-popover')), findsNothing);
    expect(find.byTooltip('Filtros (2)'), findsOneWidget);

    tester.view.physicalSize = const Size(320, 720);
    await tester.pumpAndSettle();
    expect(filterButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
