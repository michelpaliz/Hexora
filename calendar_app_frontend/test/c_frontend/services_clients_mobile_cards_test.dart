import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/tabs/clients/client_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/tabs/services/service_list_item.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('long mobile cards wrap without overflow in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
            body: ListView(padding: const EdgeInsets.all(16), children: [
          ServiceListItem(
            service: Service(
                id: 's',
                name: 'Mantenimiento de jardines y piscinas comunitarias'),
            nameStyle: const TextStyle(),
            metaStyle: const TextStyle(),
            onTap: () => tapped = true,
          ),
          ClientListItem(
            client: GroupClient(
                id: 'c',
                name: 'Comunidad de propietarios Las Alondras Playa',
                email: 'administracion.muy.larga@example.com',
                isActive: true,
                missingCurrentMonthInvoice: true,
                currentMonthInvoiceCount: 0),
            nameStyle: const TextStyle(),
            metaStyle: const TextStyle(),
          ),
        ])),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester
          .tap(find.text('Mantenimiento de jardines y piscinas comunitarias'));
      expect(tapped, isTrue);
      expect(find.text('Sin facturas este mes'), findsNothing);
    });
  }
}
