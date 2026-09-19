import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/service_catalog/service.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/tabs/services/services_tab.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  test('missing environment is not treated as indoor', () {
    final legacy = Service.fromJson({'_id': 'old', 'name': 'Garden'});
    expect(legacy.workEnvironment, 'unspecified');
    final outdoor = Service.fromJson({'_id': 'new', 'name': 'Garden', 'workEnvironment': 'outdoor', 'weatherSensitive': true});
    expect(outdoor.workEnvironment, 'outdoor');
    expect(outdoor.toJson()['workEnvironment'], 'outdoor');
    expect(outdoor.weatherSensitive, isTrue);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('services search and navigation at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? selected;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.fromBrightness(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Scaffold(
            body: ServicesTab(
                items: [
              Service(
                  id: '1',
                  name: 'Piscina exterior con mantenimiento completo',
                  workEnvironment: 'outdoor',
                  weatherSensitive: true),
              Service(id: '2', name: 'Limpieza', workEnvironment: 'mixed'),
            ],
                loading: false,
                error: null,
                onRefresh: () async {},
                onEdit: (service) => selected = service.id)),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Exterior'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'piscina');
      await tester.pumpAndSettle();
      expect(find.text('Limpieza'), findsNothing);
      await tester
          .tap(find.text('Piscina exterior con mantenimiento completo'));
      expect(selected, '1');
      await tester.enterText(find.byType(TextField), 'no match');
      await tester.pumpAndSettle();
      expect(find.text('No hay servicios que coincidan.'), findsOneWidget);
      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('Limpieza'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
