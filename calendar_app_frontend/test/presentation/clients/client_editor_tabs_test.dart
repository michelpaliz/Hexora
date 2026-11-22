import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('es'),
      theme: ThemeData(extensions: const [_typography]),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('client editor tabs preserve unsaved form state', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app(AddClientSheet(
      groupId: 'group-1',
      api: ClientsApi(),
      client: GroupClient(id: 'client-1', name: 'Cliente inicial'),
      closeOnSave: false,
      onCancel: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.text('Clasificación'), findsOneWidget);
    expect(find.text('Facturación'), findsOneWidget);
    for (final label in const [
      'General',
      'Ubicación',
      'Clasificación',
      'Facturación',
    ]) {
      expect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(ExpansionTile),
        ),
        findsNothing,
      );
    }

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Nombre sin guardar');
    await tester.tap(find.text('Clasificación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Facturación'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre de facturación'), findsOneWidget);
    expect(find.text('Prefijo en PDF (opcional)'), findsOneWidget);
    expect(find.text('Alias para PDF (opcional)'), findsOneWidget);
    expect(find.text('Vista previa en PDF'), findsOneWidget);

    final prefixField = find.ancestor(
      of: find.text('Prefijo en PDF (opcional)'),
      matching: find.byType(TextFormField),
    );
    final aliasField = find.ancestor(
      of: find.text('Alias para PDF (opcional)'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(prefixField, 'Com. de Prop.');
    await tester.enterText(aliasField, 'Residencial Norte');
    await tester.pump();

    expect(find.text('Com. de Prop. Cliente inicial'), findsOneWidget);
    expect(find.text('Residencial Norte'), findsNWidgets(2));

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();

    final restoredNameField =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(restoredNameField.controller?.text, 'Nombre sin guardar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('location has its own tab; Activo stays in General',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app(AddClientSheet(
      groupId: 'group-1',
      api: ClientsApi(),
      client: GroupClient(id: 'client-1', name: 'Cabo del Sol'),
      closeOnSave: false,
      onCancel: () {},
    )));
    await tester.pumpAndSettle();

    final activeLabel =
        AppLocalizations.of(tester.element(find.byType(AddClientSheet)))!
            .active;
    expect(find.text(activeLabel), findsOneWidget);
    expect(find.text('Dirección del servicio'), findsNothing);

    await tester.tap(find.text('Ubicación'));
    await tester.pumpAndSettle();
    expect(find.text('Dirección del servicio'), findsOneWidget);
    expect(find.text('Coordenadas'), findsOneWidget);
    expect(find.text('Geocerca'), findsOneWidget);
    expect(find.text('Ubicación actual'), findsOneWidget);
    expect(find.text(activeLabel), findsNothing);
    // Geofence settings start collapsed for a client without a geofence.
    expect(find.text('Radio de geocerca'), findsNothing);

    await tester.tap(find.text('Geocerca'));
    await tester.pumpAndSettle();
    expect(find.text('Radio de geocerca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
