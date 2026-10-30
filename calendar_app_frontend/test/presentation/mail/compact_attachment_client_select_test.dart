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
          56,
        );
        final nameTop = tester
            .getTopLeft(find.text(
              'Cliente activo con un nombre extraordinariamente largo',
            ))
            .dy;
        final emailTop = tester
            .getTopLeft(find.text(
              'facturacion-con-direccion-muy-larga@example.com',
            ))
            .dy;
        expect(nameTop, closeTo(emailTop, 2));
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

  testWidgets('shows and filters compact unsent document summaries',
      (tester) async {
    tester.view.physicalSize = const Size(720, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clients = [
      GroupClient(id: 'one', name: 'Uno', email: 'uno@example.com'),
      GroupClient(id: 'mixed', name: 'Mixto', email: 'mixto@example.com'),
      GroupClient(id: 'none', name: 'Sin pendientes', email: 'ok@example.com'),
      GroupClient(id: 'missing', name: 'Sin email'),
      GroupClient(id: 'invalid', name: 'Email incorrecto', email: 'incorrecto'),
    ];

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromBrightness(Brightness.light),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 500,
          child: ClientSearchSelect(
            clients: clients,
            selectedClientId: 'one',
            useDefaultPropertyKind: false,
            compact: true,
            unsentDocumentCounts: const {
              'one': ClientUnsentDocumentCounts(invoices: 1),
              'mixed': ClientUnsentDocumentCounts(invoices: 3, receipts: 2),
            },
            onClientChanged: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1 factura sin enviar'), findsOneWidget);
    expect(find.text('3 facturas · 2 recibos sin enviar'), findsOneWidget);
    expect(find.textContaining('0 factura'), findsNothing);
    expect(find.text('Sin correo registrado'), findsOneWidget);
    expect(find.text('Correo no válido'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('client-select-row-one')))
          .height,
      56,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('client-select-row-none')))
          .height,
      56,
    );
    expect(
      find.byTooltip(
        'Documentos sin enviar disponibles según los datos actuales del negocio',
      ),
      findsNWidgets(2),
    );

    await tester.tap(
      find.byKey(const ValueKey('client-advanced-filters-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Con documentos sin enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Uno'), findsOneWidget);
    expect(find.text('Mixto'), findsOneWidget);
    expect(find.text('Sin pendientes'), findsNothing);
    expect(find.textContaining('Filtros (1)'), findsOneWidget);
  });
}
