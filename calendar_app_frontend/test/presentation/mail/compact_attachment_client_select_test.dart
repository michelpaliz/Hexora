import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/client_search_select.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'compact attachment client selector keeps filters and rows dense in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(720, 520);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final clients = [
          GroupClient(
            id: 'active',
            name: 'Cliente activo con un nombre extraordinariamente largo',
            email: 'facturacion-con-direccion-muy-larga@example.com',
            entityType: 'empresa',
          ),
          GroupClient(
            id: 'inactive',
            name: 'Cliente inactivo',
            email: 'inactivo@example.com',
            entityType: 'empresa',
            isActive: false,
          ),
        ];
        String? selected = 'active';

        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.fromBrightness(brightness),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(builder: (context, setState) {
              return SizedBox(
                height: 420,
                child: ClientSearchSelect(
                  clients: clients,
                  selectedClientId: selected,
                  useDefaultPropertyKind: false,
                  compact: true,
                  onClientChanged: (value) => setState(() => selected = value),
                ),
              );
            }),
          ),
        ));
        await tester.pumpAndSettle();

        expect(
          tester
              .getSize(find.byKey(const ValueKey('client-select-row-active')))
              .height,
          46,
        );
        expect(find.text('Cliente inactivo'), findsNothing);
        expect(find.textContaining('Clientes activos'), findsNothing);
        expect(
          find.byTooltip(
            'Cliente activo con un nombre extraordinariamente largo',
          ),
          findsOneWidget,
        );
        expect(
          find.byTooltip('facturacion-con-direccion-muy-larga@example.com'),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('client-advanced-filters-toggle')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Clientes activos'), findsOneWidget);

        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        expect(find.text('Cliente inactivo'), findsOneWidget);
        expect(find.textContaining('Filtros (1)'), findsOneWidget);

        await tester.enterText(find.byType(TextField).first, 'inactivo@');
        await tester.pumpAndSettle();
        expect(find.text('Cliente inactivo'), findsOneWidget);
        expect(
          find.text('Cliente activo con un nombre extraordinariamente largo'),
          findsNothing,
        );

        await tester.tap(find.text('Cliente inactivo'));
        await tester.pumpAndSettle();
        expect(selected, 'inactive');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
