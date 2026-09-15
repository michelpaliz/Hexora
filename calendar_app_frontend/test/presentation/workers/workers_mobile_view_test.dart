import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/mobile/workers_mobile_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('workers mobile $brightness at $scale text scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var registered = false;
        String? edited;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.fromBrightness(brightness)
              .copyWith(platform: TargetPlatform.android),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(bottom: 34)),
            child: child!,
          ),
          home: Scaffold(
              body: WorkersMobileView(
            workers: List.generate(
                30,
                (i) => Worker(
                      id: '$i',
                      groupId: 'group',
                      status: WorkerStatus.active,
                      displayName: i == 0
                          ? 'Anderson con un nombre muy largo'
                          : 'Empleado $i',
                      roleTag: 'Mantenimiento y servicios de jardinería',
                      defaultHourlyRate: 1234.56,
                      currency: 'EUR',
                    )),
            summary: const Text('sept 2026 · Coste: 123,00 EUR'),
            onRefresh: () async {},
            onAddWorker: () {},
            onRegisterHours: () => registered = true,
            onAddHours: (_) {},
            onEdit: (worker) => edited = worker.id,
            onOverview: (_) {},
          )),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(WorkersMobileView));
        final l = AppLocalizations.of(context)!;
        final cta = find.byWidgetPredicate((widget) => widget is FilledButton);
        expect(tester.getBottomRight(cta).dy, lessThanOrEqualTo(816));
        await tester.tap(cta);
        expect(registered, isTrue);
        await tester.enterText(find.byType(TextField), 'Anderson');
        await tester.pumpAndSettle();
        expect(find.text('Empleado 1'), findsNothing);
        final menu = find.byTooltip('Acciones del trabajador');
        await tester.ensureVisible(menu);
        await tester.pumpAndSettle();
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.editWorker));
        await tester.pumpAndSettle();
        expect(edited, '0');
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), 'sin coincidencias');
        await tester.pumpAndSettle();
        expect(find.text('No hay trabajadores que coincidan.'), findsOneWidget);
      });
    }
  }
}
