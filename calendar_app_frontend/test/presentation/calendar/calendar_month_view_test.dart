import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/adapter_flow/view/calendar_surface.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_month_cell.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_styles.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/widgets/calendar_tabs.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/widgets/calendar_topbar.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  testWidgets('calendar views use a compact segmented control on phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedIndex = -1;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DefaultTabController(
        length: 4,
        child: Builder(
          builder: (context) => Scaffold(
            appBar: CalendarTopBar(
              title: 'Calendar',
              tabs: CalendarTabs.build(context, large: true),
              onTabChanged: (index) => selectedIndex = index,
            ),
            body: const TabBarView(
              children: [
                Text('day view'),
                Text('week view'),
                Text('month view'),
                Text('agenda view'),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(TabBar)).height, 48);
    await tester.tap(find.text(AppLocalizations.of(
      tester.element(find.byType(CalendarTopBar)),
    )!
        .tabMonth));
    await tester.pumpAndSettle();

    expect(selectedIndex, 2);
    expect(find.text('month view'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('compact month cells fit five and six week grids on phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      for (final weekCount in [5, 6]) {
        final dates = List.generate(
          weekCount * 7,
          (index) => DateTime(2026, 8, 1).add(Duration(days: index)),
        );
        final cellHeight = weekCount == 6 ? 34.0 : 42.0;
        final events = List.generate(
          4,
          (index) => Event(
            id: 'mobile-event-$index',
            startDate: dates.first.add(Duration(hours: 8 + index)),
            endDate: dates.first.add(Duration(hours: 9 + index)),
            title: 'Evento ${index + 1}',
            ownerId: 'owner',
            eventColorIndex: index,
          ),
        );

        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light.copyWith(platform: platform),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.5),
              ),
              child: GridView.builder(
                itemCount: dates.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: cellHeight,
                ),
                itemBuilder: (context, index) => buildMonthCell(
                  context: context,
                  details: MonthCellDetails(
                    dates[index],
                    const [],
                    dates,
                    Rect.fromLTWH(0, 0, 320 / 7, cellHeight),
                  ),
                  selectedDate: dates.first,
                  events: events,
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Tooltip), findsNWidgets(dates.length));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Syncfusion month view fits five and six rows on small phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      tester.view.physicalSize = size;
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        for (final month in [DateTime(2026, 6, 1), DateTime(2026, 8, 1)]) {
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light.copyWith(platform: platform),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
              ),
              child: child!,
            ),
            home: Scaffold(
              appBar: const PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: SizedBox(),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 62),
                    Expanded(
                      child: SfCalendar(
                        initialDisplayDate: month,
                        initialSelectedDate: month,
                        view: CalendarView.month,
                        headerHeight: 40,
                        viewHeaderHeight: 32,
                        showNavigationArrow: true,
                        showDatePickerButton: true,
                        showTodayButton: true,
                        firstDayOfWeek: DateTime.monday,
                        monthCellBuilder: (context, details) => buildMonthCell(
                          context: context,
                          details: details,
                          selectedDate: month,
                          events: const [],
                        ),
                        monthViewSettings: buildMonthSettings(
                          showAgenda: true,
                          agendaItemHeight: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }
      }
    }
  });
}
