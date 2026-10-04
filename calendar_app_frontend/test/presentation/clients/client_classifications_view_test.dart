import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/i_token_store.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/client_billing.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/client_classifications_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/client_classification_store.dart';
import 'package:hexora/theme/themes/app_theme.dart';

final clients = [
  for (var i = 0; i < 10; i++)
    GroupClient(
        id: '$i',
        name: 'Cliente ${i.toString().padLeft(2, '0')}',
        entityType: 'comunidad',
        propertyKind: i == 0 ? 'chalet' : 'apartamento',
        isActive: i != 0,
        billing: ClientBilling(addressCity: i == 0 ? 'Oliva' : 'Dénia')),
  GroupClient(id: 'missing', name: 'Sin asignar', entityType: null),
];

class _Tokens implements TokenStore {
  @override
  Future<String?> readAccess() async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpScreen(WidgetTester tester, double width,
    {Future<void> Function(GroupClient)? delete,
    Future<GroupClient> Function(GroupClient, Map<String, dynamic>)?
        update}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('es'),
    theme: AppTheme.fromBrightness(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
        body: ClientClassificationsView(
      groupId: 'group',
      clients: clients,
      onDeleteClient: delete,
      onUpdateClient: update,
      loadOptions: (_) async => const ClientClassificationOptions(
          entityTypes: ['comunidad', 'empresa', 'emp résa'],
          propertyKinds: ['chalet', 'apartamento']),
    )),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('changing entity classification patches only the selected field',
      (tester) async {
    TokenService.configureStore(_Tokens());
    addTearDown(() => TokenService.configureStore(SecureTokenStore()));
    final patches = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await pumpScreen(tester, 1536, update: (client, fields) async {
        patches.add(fields);
        return client.copyWith(entityType: fields['entityType'] as String?);
      });
      tester
          .widget<DataTable>(find.byType(DataTable))
          .rows
          .first
          .onSelectChanged!(true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar clasificación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tipo de entidad').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'empresa');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(patches, [
        {'entityType': 'empresa'}
      ]);
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.rows.length, 1);
      expect((table.rows.single.cells[1].child as Text).data, 'Chalet');
      expect(find.text('Clasificación actualizada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async => http.Response(
            jsonEncode({
              'entityTypes': ['comunidad', 'empresa'],
              'propertyKinds': ['chalet', 'apartamento'],
            }),
            200)));
  });
  for (final width in [390.0, 1536.0]) {
    testWidgets(
        'classification layout at $width uses actual counts and pagination',
        (tester) async {
      await pumpScreen(tester, width);
      expect(tester.takeException(), isNull);
      expect(find.text('11'), findsOneWidget);
      expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 8);
      final next = find.byTooltip('Página siguiente');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 2);
      expect(find.text('Mostrando 9–10 de 10 clientes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'search filters rows and clears selection; unclassified includes missing values',
      (tester) async {
    await pumpScreen(tester, 1536);
    final table = tester.widget<DataTable>(find.byType(DataTable));
    table.rows.first.onSelectChanged!(true);
    await tester.pumpAndSettle();
    expect(find.text('1 seleccionados'), findsOneWidget);
    final search = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Buscar clientes…');
    await tester.enterText(search, 'Cliente 09');
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 1);
    expect(find.text('0 seleccionados'), findsOneWidget);
    await tester.enterText(search, '');
    await tester.tap(find.widgetWithText(ListTile, 'Sin clasificar').first);
    await tester.pumpAndSettle();
    expect(find.text('Sin asignar'), findsOneWidget);
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'bulk delete reports partial failure and retains unsuccessful rows',
      (tester) async {
    await pumpScreen(tester, 1536, delete: (client) async {
      if (client.id == '1') throw StateError('Cannot delete');
    });
    final table = tester.widget<DataTable>(find.byType(DataTable));
    table.rows[0].onSelectChanged!(true);
    table.rows[1].onSelectChanged!(true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Cliente 00'), findsNothing);
    expect(find.text('Cliente 01'), findsOneWidget);
    expect(find.text('1 seleccionados'), findsOneWidget);
    expect(find.textContaining('1 eliminados.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
