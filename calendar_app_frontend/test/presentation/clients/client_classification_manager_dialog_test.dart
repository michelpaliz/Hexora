import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/services/auth/token/i_token_store.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/client_classification_manager_dialog.dart';

class _Tokens implements TokenStore {
  @override
  Future<String?> readAccess() async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const options = {
  'entityTypes': ['empresa', 'hotel'],
  'propertyKinds': ['chalet']
};
Future<void> open(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  TokenService.configureStore(_Tokens());
  addTearDown(() => TokenService.configureStore(SecureTokenStore()));
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('es'),
    theme: AppTheme.fromBrightness(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ClientClassificationManagerDialog(
                            groupId: 'g',
                            clients: [
                              GroupClient(
                                  id: 'a',
                                  name: 'A',
                                  entityType: 'empresa',
                                  propertyKind: 'chalet')
                            ])),
                child: const Text('Open')))),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('edits stay local until save at width $width', (tester) async {
      final writes = <Map<String, dynamic>>[];
      await http.runWithClient(() async {
        await open(tester, width);
        expect(tester.takeException(), isNull);
        expect(find.text('1 cliente'), findsNWidgets(2));
        await tester.enterText(find.byType(TextFormField).first, 'Comunidad');
        await tester.tap(find.byTooltip('Eliminar opción').at(1));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        await tester.tap(find.text('Restablecer'));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(find.text('empresa'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).first, 'Comunidad');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar cambios'));
        await tester.pumpAndSettle();
        expect(writes.single['entityTypes'], ['comunidad', 'hotel']);
        expect(writes.single['propertyKinds'], ['chalet']);
        expect(find.byType(ClientClassificationManagerDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
          () => MockClient((r) async {
                if (r.method == 'PUT') {
                  writes.add(jsonDecode(r.body) as Map<String, dynamic>);
                }
                return http.Response(jsonEncode(options), 200,
                    headers: {'content-type': 'application/json'});
              }));
    });
  }
  testWidgets('duplicates block saving and cancel discards without a request',
      (tester) async {
    var writes = 0;
    await http.runWithClient(() async {
      await open(tester, 1200);
      await tester.enterText(find.byType(TextFormField).first, 'HOTEL');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Esta opción ya existe'), findsWidgets);
      expect(writes, 0);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.byType(ClientClassificationManagerDialog), findsNothing);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              if (r.method != 'GET') writes++;
              return http.Response(jsonEncode(options), 200,
                  headers: {'content-type': 'application/json'});
            }));
  });
  testWidgets('add and reorder survive a save failure and retry',
      (tester) async {
    final writes = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await open(tester, 1200);
      await tester.tap(find.text('Añadir opción').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'Particular');
      await tester.pumpAndSettle();
      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView).first)
          .onReorder(2, 0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.byType(ClientClassificationManagerDialog), findsOneWidget);
      expect(find.textContaining('Tus ediciones se conservan'), findsOneWidget);
      expect(writes.single['entityTypes'], ['particular', 'empresa', 'hotel']);
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(writes.length, 2);
      expect(writes[1], writes[0]);
      expect(find.byType(ClientClassificationManagerDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              if (r.method == 'PUT') {
                writes.add(jsonDecode(r.body) as Map<String, dynamic>);
                if (writes.length == 1) return http.Response('{}', 500);
              }
              return http.Response(jsonEncode(options), 200,
                  headers: {'content-type': 'application/json'});
            }));
  });
}
