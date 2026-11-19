import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_client_step.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('recurring client step uses one compact filter toolbar',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final name = TextEditingController();
    final currency = TextEditingController(text: 'EUR');
    final notes = TextEditingController();
    addTearDown(name.dispose);
    addTearDown(currency.dispose);
    addTearDown(notes.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.fromBrightness(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: RecurringWizardClientStep(
              clients: [
                GroupClient(
                  id: 'active',
                  name: 'Cliente activo',
                  email: 'activo@example.com',
                  propertyKind: 'comunidad de propietarios',
                ),
                GroupClient(
                  id: 'inactive',
                  name: 'Cliente inactivo',
                  email: 'inactivo@example.com',
                  propertyKind: 'comunidad de propietarios',
                  isActive: false,
                ),
              ],
              clientId: 'active',
              onClientChanged: (_) {},
              nameCtrl: name,
              currencyCtrl: currency,
              notesCtrl: notes,
              showRuleFields: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cliente'), findsNothing);
    expect(find.textContaining('Clientes activos 1'), findsOneWidget);
    expect(find.textContaining('Filtros (1)'), findsOneWidget);
    expect(find.text('Con documentos sin enviar'), findsNothing);
    expect(find.text('Cliente inactivo'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('client-select-row-active')))
          .height,
      50,
    );

    final searchTop = tester.getTopLeft(find.byType(TextField)).dy;
    final filtersTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('client-advanced-filters-toggle')),
        )
        .dy;
    expect(searchTop, closeTo(filtersTop, 2));

    await tester.tap(
      find.byKey(const ValueKey('client-advanced-filters-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Con documentos sin enviar'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(320, 720);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('client-advanced-filters-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Con documentos sin enviar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
