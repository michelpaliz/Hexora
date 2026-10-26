import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/adapter_flow/view/calendar_surface.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_month_cell.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_styles.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  test('sidebar calendar modes map to their real layouts', () {
    expect(calendarViewModeForSideMenu('week'), 'week');
    expect(calendarViewModeForSideMenu('day'), 'day');
    expect(calendarViewModeForSideMenu('agenda'), 'agenda');
    expect(calendarViewModeForSideMenu('month'), 'month');
    expect(calendarViewForMode('week'), CalendarView.week);
    expect(calendarViewForMode('day'), CalendarView.day);
    expect(calendarViewForMode('agenda'), CalendarView.schedule);
    expect(calendarViewForMode('month'), CalendarView.month);
  });

  test('month settings use a horizontal grid with adjacent dates', () {
    final settings = buildMonthSettings(showAgenda: false);
    expect(settings.showAgenda, isFalse);
    expect(settings.showTrailingAndLeadingDates, isTrue);
    expect(
      settings.navigationDirection,
      MonthNavigationDirection.horizontal,
    );
  });

  testWidgets('month cell shows events and a compact overflow count',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final date = DateTime(2026, 10, 15);
    final events = List.generate(
      4,
      (index) => Event(
        id: 'event-$index',
        startDate: date.add(Duration(hours: 8 + index)),
        endDate: date.add(Duration(hours: 9 + index)),
        title: 'Evento ${index + 1}',
        ownerId: 'owner',
        eventColorIndex: index,
      ),
    );
    Event? tapped;
    final visibleDates = List.generate(
      42,
      (index) => DateTime(2026, 9, 28).add(Duration(days: index)),
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: SizedBox(
              width: 220,
              height: 110,
              child: buildMonthCell(
                context: context,
                details: MonthCellDetails(
                  date,
                  const [],
                  visibleDates,
                  const Rect.fromLTWH(0, 0, 220, 110),
                ),
                selectedDate: null,
                events: events,
                onEventTap: (event) => tapped = event,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Evento 1'), findsOneWidget);
    expect(find.text('Evento 2'), findsOneWidget);
    expect(find.text('Evento 3'), findsOneWidget);
    expect(find.text('+1 más'), findsOneWidget);
    expect(find.text('Evento 4'), findsNothing);

    await tester.tap(find.text('Evento 1'));
    expect(tapped?.id, 'event-0');
    expect(tester.takeException(), isNull);
  });
}
