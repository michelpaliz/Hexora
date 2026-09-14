import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/group_model/client/client.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

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

Widget _app(Widget child, {bool dark = false}) => MaterialApp(
      locale: const Locale('es'),
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        extensions: const [_typography],
      ),
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
  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('editor at width $width keeps save visible at scale $scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final client = GroupClient(
          id: 'client-1',
          name: 'Las Alondras Playa',
          propertyKind: 'comunidad de propietarios con un nombre largo',
          entityType: 'comunidad de propietarios',
        );
        await tester.pumpWidget(_app(Builder(builder: (context) {
          return TextButton(
            onPressed: () => showClientEditor(
              context: context,
              groupId: 'group-1',
              api: ClientsApi(),
              client: client,
            ),
            child: const Text('Open editor'),
          );
        }), dark: width > 600));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        if (width > 600) {
          final fieldContext = tester.element(find.byType(TextFormField).first);
          expect(Theme.of(fieldContext).brightness, Brightness.dark);
          expect(tester.getSize(find.byType(TextFormField).first).width,
              lessThanOrEqualTo(808));
        }
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.text('Guardar cambios').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        final savePosition = tester.getCenter(find.text('Guardar cambios'));
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -450));
        await tester.pumpAndSettle();
        expect(tester.getCenter(find.text('Guardar cambios')), savePosition);
        // Expand both optional sections and verify their narrow layouts.
        for (final tile in find.byType(ExpansionTile).evaluate().toList()) {
          final finder = find.byWidget(tile.widget);
          await tester.ensureVisible(finder);
          await tester.tap(find
              .descendant(of: finder, matching: find.byType(ListTile))
              .first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        tester.view.viewInsets =
            FakeViewPadding(bottom: 300 * tester.view.devicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(find.text('Guardar cambios').hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(find.text('Guardar cambios')).dy,
            lessThan(500));
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Open editor'), findsOneWidget);
        expect(find.byType(AddClientSheet), findsNothing);
      });
    }
  }
}
