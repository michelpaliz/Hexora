import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/calendar/agenda_model.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/agenda/widgets/agenda_header.dart';
import 'package:hexora/presentation/screens/agenda/widgets/agenda_sliver.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('agenda readable and interactive: $brightness / $scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final today = DateUtils.dateOnly(DateTime.now());
        final event = Event(
            id: 'visit',
            title: 'Mantenimiento piscina — Sueño de Denia IV',
            ownerId: 'owner',
            type: 'work_visit',
            startDate: today.add(const Duration(hours: 17)),
            endDate: today.add(const Duration(hours: 18)),
            isDone: true);
        final item = AgendaItem(event: event, color: Colors.blue);
        DateTime? selected;
        var toggles = 0;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.fromBrightness(brightness),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          routes: {
            AppRoutes.eventDetail: (context) => Scaffold(
                body: Text(
                    (ModalRoute.of(context)!.settings.arguments as Event).id))
          },
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Column(children: [
            AgendaHeader(
                items: [item],
                daysRange: 14,
                selectedDay: today,
                onSelectDay: (day) => selected = day,
                onExpandRange: () => toggles++,
                onRefresh: () {}),
            AgendaTile(item: item),
          ]))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('✓ Completado'), findsOneWidget);
        await tester.tap(find.text('30d'));
        expect(toggles, 1);
        final dayChip = find.byType(ChoiceChip).at(2);
        await tester.ensureVisible(dayChip);
        await tester.tap(dayChip);
        expect(selected, today.add(const Duration(days: 1)));
        await tester.ensureVisible(find.text(event.title));
        await tester.tap(find.text(event.title));
        await tester.pumpAndSettle();
        expect(find.text('visit'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
