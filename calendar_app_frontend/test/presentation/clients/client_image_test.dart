import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/client_property_image.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_image_field.dart';

Widget app(Widget child, {String language = 'es'}) => MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  test('existing clients need no image; image version survives copies', () {
    expect(
        GroupClient.fromJson({'id': '1', 'name': 'Las Alondras'}).imageVersion,
        isNull);
    final client = GroupClient.fromJson({
      'id': '1',
      'name': 'Las Alondras',
      'image': {'updatedAt': '2026-10-04T10:00:00Z'}
    });
    expect(client.copyWith(name: 'Updated').imageVersion, client.imageVersion);
    expect(client.toJson().containsKey('image'), isFalse);
    expect(
        GroupClient.fromJson({'id': '1', 'image': null}).imageVersion, isNull);
  });

  testWidgets('no photo shows initial and changes with selected client',
      (tester) async {
    await tester.pumpWidget(app(ClientPropertyImage(
        client: GroupClient(id: '1', name: 'Las Alondras'))));
    await tester.pumpAndSettle();
    expect(find.text('L'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(
        app(ClientPropertyImage(client: GroupClient(id: '2', name: 'Hotel'))));
    await tester.pumpAndSettle();
    expect(find.text('L'), findsNothing);
    expect(find.text('H'), findsOneWidget);
  });

  for (final language in ['es', 'en']) {
    testWidgets('optional photo field at mobile width in $language',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool removed = false;
      final image = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aC9sAAAAASUVORK5CYII=');
      await tester.pumpWidget(app(
          ClientImageField(
            client: GroupClient(id: '1', name: 'Las Alondras'),
            bytes: image,
            onChanged: (_, __) {},
            onRemove: () => removed = true,
          ),
          language: language));
      await tester.pumpAndSettle();
      expect(
          find.text(language == 'es'
              ? 'Imagen del cliente / ubicación'
              : 'Client / location image'),
          findsOneWidget);
      await tester
          .tap(find.text(language == 'es' ? 'Quitar imagen' : 'Remove image'));
      expect(removed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
