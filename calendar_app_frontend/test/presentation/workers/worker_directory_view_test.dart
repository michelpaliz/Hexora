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
      var selectedStatus = WorkerStatusFilter.all;
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
            statusFilter: WorkerStatusFilter.all,
            onStatusFilterChanged: (value) => selectedStatus = value,
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
      expect(find.text('9–10 / 10 trabajadores'), findsOneWidget);
      expect(
          tester
              .widget<TextButton>(find.descendant(
                of: find.byTooltip('Página siguiente'),
                matching: find.byType(TextButton),
              ))
              .onPressed,
          isNull);
      final search = find.byType(TextField);
      await tester.ensureVisible(search);
      await tester.enterText(search, 'Worker 00');
      await tester.pumpAndSettle();
      expect(list().workers.single.id, '0');
      expect(find.text('1 trabajadores'), findsOneWidget);
      if (width >= 840) {
        await tester.tap(find.byTooltip('Vista de tarjetas'));
      } else {
        await tester.tap(find.byTooltip('Opciones de vista'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vista de tarjetas'));
      }
      await tester.pumpAndSettle();
      expect(list().grid, isTrue);
      if (width >= 840) {
        await tester.tap(find.byTooltip('Vista de lista'));
      } else {
        await tester.tap(find.byTooltip('Opciones de vista'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vista de lista'));
      }
      await tester.pumpAndSettle();
      expect(list().grid, isFalse);
      if (width >= 840) {
        await tester.tap(find.text('Activos'));
      } else {
        await tester.tap(find.byTooltip('Filtros'));
        await tester.pumpAndSettle();
        await tester.tap(find.byWidgetPredicate((widget) =>
            widget is CheckedPopupMenuItem<WorkerStatusFilter> &&
            widget.value == WorkerStatusFilter.active));
      }
      await tester.pumpAndSettle();
      expect(selectedStatus, WorkerStatusFilter.active);
      expect(tester.takeException(), isNull);
    });
  }
}
