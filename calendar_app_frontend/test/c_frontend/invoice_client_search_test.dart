import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/mobile/mobile_client_search_list.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/mobile_section_tabs.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets('search filters clients and survives tab changes and details',
      (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late TabController tabs;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.android),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!),
      home: DefaultTabController(
          length: 4,
          initialIndex: 2,
          child: Builder(builder: (context) {
            tabs = DefaultTabController.of(context);
            return Scaffold(
                body: Column(children: [
              MobileSectionTabs(
                  controller: tabs,
                  scrollable: true,
                  labels: const [
                    'Facturas',
                    'Recibos',
                    'Clientes',
                    'Presupuestos'
                  ]),
              Expanded(
                  child: TabBarView(controller: tabs, children: [
                const Center(child: Text('Invoice page')),
                const Center(child: Text('Receipt page')),
                MobileClientSearchList(
                    clients: [
                      GroupClient(
                          id: '1',
                          name: 'Alqueria',
                          email: 'mayvi@example.com'),
                      GroupClient(
                          id: '2', name: 'Belman', email: 'conta@example.com'),
                    ],
                    itemBuilder: (context, client) => ListTile(
                        title: Text(client.name),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => Scaffold(
                                    appBar:
                                        AppBar(title: Text(client.name))))))),
                const Center(child: Text('Budget page')),
              ])),
            ]));
          })),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
    await tester.enterText(find.byType(TextField), 'MAYVI@');
    await tester.pumpAndSettle();
    expect(find.text('Alqueria'), findsOneWidget);
    expect(find.text('Belman'), findsNothing);
    await tester.tap(find.text('Alqueria'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('MAYVI@'), findsOneWidget);
    tabs.animateTo(3);
    await tester.pumpAndSettle();
    expect(find.text('Presupuestos').hitTestable(), findsOneWidget);
    tabs.animateTo(2);
    await tester.pumpAndSettle();
    expect(find.text('MAYVI@'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no match');
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron clientes'), findsOneWidget);
    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Belman'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
