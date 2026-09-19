import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/worker_selection_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/actions_section.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('worker selection and save fit 320px at ${scale}x',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selected = <String>{};
      var saved = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: StatefulBuilder(builder: (context, update) {
          return SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              WorkerSelectionSection(
                workers: const [
                  Worker(
                      id: 'one',
                      groupId: 'group',
                      displayName: 'Trabajador con un nombre muy largo',
                      status: WorkerStatus.active)
                ],
                selectedIds: selected,
                onSelectAll: () => update(() => selected.add('one')),
                onClear: () => update(selected.clear),
                onToggle: (id, value) => update(() {
                  value ? selected.add(id) : selected.remove(id);
                }),
              ),
              ActionsSection(
                  l: AppLocalizations.of(context)!,
                  saving: false,
                  onSave: () => saved = true),
            ]),
          ));
        })),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Seleccionar todos'));
      await tester.pumpAndSettle();
      expect(selected, {'one'});
      await tester.tap(find.text('Limpiar selección'));
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
      final save = find.byWidgetPredicate((widget) => widget is FilledButton);
      await tester.ensureVisible(save);
      await tester.tap(save);
      expect(saved, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
