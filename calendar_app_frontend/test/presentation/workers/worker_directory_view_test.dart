import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/worker_directory_view.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/status_filter_chips.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_list_section.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final width in [600.0, 1400.0]) {
    testWidgets('directory pagination, search and card view at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.fromBrightness(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: Padding(
          padding: const EdgeInsets.all(16),
          child: WorkerDirectoryView(
            group: Group(
                id: 'group',
                name: 'Team',
                ownerId: 'owner',
                userRoles: {},
                userIds: [],
                createdTime: DateTime(2026),
                description: ''),
            workers: List.generate(
                10,
                (i) => Worker(
                    id: '$i',
                    groupId: 'group',
                    displayName: 'Worker ${i.toString().padLeft(2, '0')}',
                    status: WorkerStatus.active,
                    defaultHourlyRate: 6,
                    advanceAmount: 60,
                    roleTag: 'Jardinero')),
            showPartners: false,
            onTabChanged: (_) {},
            monthSummary: const Text('octubre de 2026'),
            statusFilter: StatusFilterChips(
                value: WorkerStatusFilter.all, onChanged: (_) {}),
            onCreate: () {},
            onEdit: (_) {},
            onAddHours: (_) {},
            onOverview: (_) {},
          ),
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      WorkerListSection list() =>
          tester.widget<WorkerListSection>(find.byType(WorkerListSection));
      expect(list().workers.length, 8);
      expect(list().workers.first.advanceAmount, 60);
      expect(find.textContaining('Ant.'), findsNothing);
      expect(find.byTooltip('Ant. 60 EUR'), findsNothing);
      final next = find.byTooltip('Página siguiente');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(list().workers.map((w) => w.id), ['8', '9']);
      expect(find.text('Mostrando 9–10 de 10 trabajadores'), findsOneWidget);
      expect(
          tester
              .widget<IconButton>(find.byWidgetPredicate((widget) =>
                  widget is IconButton && widget.tooltip == 'Página siguiente'))
              .onPressed,
          isNull);
      final search = find.byType(TextField);
      await tester.ensureVisible(search);
      await tester.enterText(search, 'Worker 00');
      await tester.pumpAndSettle();
      expect(list().workers.single.id, '0');
      expect(find.text('Mostrando 1 de 1 trabajadores'), findsOneWidget);
      await tester.tap(find.byTooltip('Vista de tarjetas'));
      await tester.pumpAndSettle();
      expect(list().grid, isTrue);
      await tester.tap(find.byTooltip('Vista de lista'));
      await tester.pumpAndSettle();
      expect(list().grid, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
