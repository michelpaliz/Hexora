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

    expect(find.text('Información general'), findsOneWidget);
    expect(find.text('Clasificación'), findsOneWidget);
    expect(find.text('Facturación'), findsOneWidget);
    for (final label in const [
      'Información general',
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
    await tester.tap(find.text('Información general'));
    await tester.pumpAndSettle();

    final restoredNameField =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(restoredNameField.controller?.text, 'Nombre sin guardar');
    expect(tester.takeException(), isNull);
  });
}
