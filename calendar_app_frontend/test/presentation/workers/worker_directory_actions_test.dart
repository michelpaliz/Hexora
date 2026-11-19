import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_directory_card.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('worker row promotes hours and keeps secondary actions in menu',
      (tester) async {
    var overviewCalls = 0;
    var addHoursCalls = 0;
    var editCalls = 0;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromBrightness(Brightness.light),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 800,
          child: WorkerDirectoryCard(
            worker: const Worker(
              id: 'worker-1',
              groupId: 'group-1',
              displayName: 'Amir',
              status: WorkerStatus.active,
              defaultHourlyRate: 6,
              currency: 'EUR',
              roleTag: 'Jardinero',
            ),
            selected: false,
            onOverview: () => overviewCalls++,
            onAddHours: () => addHoursCalls++,
            onEdit: () => editCalls++,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ver horas'), findsOneWidget);
    expect(find.text('Registrar horas'), findsNothing);
    expect(find.text('Editar trabajador'), findsNothing);

    await tester.tap(find.text('Ver horas'));
    expect(overviewCalls, 1);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Registrar horas'), findsOneWidget);
    expect(find.text('Editar trabajador'), findsOneWidget);

    await tester.tap(find.text('Registrar horas'));
    await tester.pumpAndSettle();
    expect(addHoursCalls, 1);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar trabajador'));
    await tester.pumpAndSettle();
    expect(editCalls, 1);
  });

  testWidgets('compact worker row keeps hours available as a tooltip action',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromBrightness(Brightness.light),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: WorkerDirectoryCard(
            worker: const Worker(
              id: 'worker-1',
              groupId: 'group-1',
              displayName: 'Amir',
              status: WorkerStatus.active,
            ),
            selected: false,
            grid: true,
            onOverview: () {},
            onAddHours: () {},
            onEdit: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ver horas'), findsNothing);
    expect(find.byTooltip('Ver horas'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
