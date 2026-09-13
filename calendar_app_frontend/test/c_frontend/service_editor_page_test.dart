import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_service_sheet.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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

class _ServiceApi extends ServiceApi {
  final response = Completer<Service>();
  int calls = 0;
  Map<String, dynamic>? patch;
  Service? created;

  @override
  Future<Service> create(Service service) {
    calls++;
    created = service;
    return response.future;
  }

  @override
  Future<Service> updateFields(String id, Map<String, dynamic> fields) {
    calls++;
    patch = fields;
    return response.future;
  }
}

void main() {
  for (final width in [360.0, 1280.0]) {
    for (final edit in [false, true]) {
      testWidgets('service page width $width edit $edit navigates and saves',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        tester.view.padding = const FakeViewPadding(bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final api = _ServiceApi();
        final service = Service(
            id: 'service-1',
            name: 'Mantenimiento de jardín',
            defaultMinutes: 45,
            color: '#10b981');
        Service? result;
        await tester.pumpWidget(_app(Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              result = await showServiceEditor(
                  context: context,
                  groupId: 'group-1',
                  api: api,
                  service: edit ? service : null);
            },
            child: const Text('Open service'),
          );
        }), dark: width > 600));
        await tester.tap(find.text('Open service'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(BackButton), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(api.calls, 0);
        await tester.tap(find.text('Open service'));
        await tester.pumpAndSettle();
        final save = find.byWidgetPredicate((widget) => widget is FilledButton);
        expect(save.hitTestable(), findsOneWidget);
        if (width > 600) {
          expect(Theme.of(tester.element(save)).brightness, Brightness.dark);
          expect(tester.getSize(find.byType(TextFormField).first).width,
              lessThanOrEqualTo(808));
        }
        if (!edit) {
          await tester.tap(save);
          await tester.pump();
          expect(api.calls, 0);
          expect(
              tester
                  .widget<TextFormField>(find.byType(TextFormField).first)
                  .controller
                  ?.text,
              isEmpty);
        }
        await tester.enterText(find.byType(TextFormField).first, 'Jardín');
        await tester.enterText(find.byType(TextFormField).last, '60');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(500));
        expect(tester.takeException(), isNull);
        await tester.tap(save);
        await tester.tap(save);
        await tester.pump();
        expect(api.calls, 1);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        if (edit) {
          expect(api.patch?['name'], 'Jardín');
          expect(api.patch?['defaultMinutes'], 60);
          expect(api.patch?['color'], '#10b981');
        } else {
          expect(api.created?.name, 'Jardín');
          expect(api.created?.defaultMinutes, 60);
        }
        api.response
            .complete(service.copyWith(name: 'Jardín', defaultMinutes: 60));
        await tester.pumpAndSettle();
        expect(find.text('Open service'), findsOneWidget);
        expect(result?.name, 'Jardín');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
