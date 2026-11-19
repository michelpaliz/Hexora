import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/client_billing.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/tabs/clients/client_list_item.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';

void main() {
  for (final width in [320.0, 970.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('client row preserves actions at $width scale $scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        var edited = false;
        var deleted = false;
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
              brightness: width > 700 ? Brightness.dark : Brightness.light),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topCenter,
                  child: ClientListItem(
                    client: GroupClient(
                        id: '1',
                        name: 'Comunidad de propietarios Las Alondras Playa',
                        email: 'contacto.muy.largo@comunidad.example.com',
                        phone: '123456789',
                        entityType: 'Comunidad de propietarios',
                        propertyKind: 'Chalet',
                        billing: const ClientBilling(isComplete: true)),
                    selected: true,
                    nameStyle: const TextStyle(),
                    metaStyle: const TextStyle(),
                    onTap: () => edited = true,
                    onDelete: () => deleted = true,
                  ))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(HexoraStatusBadge), findsNothing);
        if (scale == 1) {
          expect(tester.getSize(find.byType(HexoraListRow)).height,
              lessThanOrEqualTo(60));
        }
        await tester
            .tap(find.text('Comunidad de propietarios Las Alondras Playa'));
        expect(edited, isTrue);
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(ClientListItem));
        await tester.tap(find.text(AppLocalizations.of(context)!.remove));
        await tester.pumpAndSettle();
        expect(deleted, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
