import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/events/screens/actions/add_screen/function/helper/add_event_helpers.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/event_form_work_visit.dart';
import 'package:hexora/theme/themes/app_theme.dart';

class _FormHost extends StatefulWidget {
  const _FormHost({super.key, this.quickMode = false, this.onMoreOptions});

  final bool quickMode;
  final VoidCallback? onMoreOptions;

  @override
  State<_FormHost> createState() => _FormHostState();
}

class _FormHostState extends BaseEventLogic<_FormHost> {
  @override
  Future<bool> addEvent(BuildContext context) async => true;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: EventFormWorkVisit(
          logic: this,
          ownerUserId: 'owner',
          onSubmit: () async {},
          showSubmitButton: false,
          quickMode: widget.quickMode,
          onMoreOptions: widget.onMoreOptions,
          enableClientServicePickers: false,
        ),
      );
}

void main() {
  test('new event carries the selected reminder', () {
    final event = buildNewEvent(
      id: 'event-1',
      startDate: DateTime.utc(2026, 9, 18, 9),
      endDate: DateTime.utc(2026, 9, 18, 10),
      title: 'Visit',
      groupId: 'group-1',
      calendarId: 'calendar-1',
      recurrenceRule: null,
      location: '',
      description: '',
      eventColorIndex: 0,
      recipients: const [],
      ownerId: 'owner-1',
      reminderTime: 30,
    );
    expect(event.toBackendJson()['reminderTime'], 30);
  });

  testWidgets('compact phone form keeps options usable at larger text size',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey<_FormHostState>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.android,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.4)),
        child: child!,
      ),
      home: Scaffold(body: _FormHost(key: key)),
    ));
    await tester.pumpAndSettle();

    final l =
        AppLocalizations.of(tester.element(find.byType(EventFormWorkVisit)))!;
    expect(find.text(l.eventFormMoreOptions), findsOneWidget);
    expect(find.text('Se requiere al menos una foto para finalizar'),
        findsNothing);
    expect(find.text('Añadir evento'), findsNothing);

    await tester.ensureVisible(find.text(l.eventFormMoreOptions));
    await tester.tap(find.text(l.eventFormMoreOptions));
    await tester.pumpAndSettle();
    expect(find.text('Se requiere al menos una foto para finalizar'),
        findsOneWidget);

    await tester.ensureVisible(find.text('Fotos obligatorias'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(key.currentState!.requiresCompletionPhotos, isTrue);

    await tester
        .ensureVisible(find.textContaining('Recordatorio · 10 minutos antes'));
    await tester.tap(find.textContaining('Recordatorio · 10 minutos antes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('30 minutos antes'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 minutos antes').last);
    await tester.pumpAndSettle();
    expect(key.currentState!.reminderMinutes, 30);
    expect(
        find.textContaining('Recordatorio · 30 minutos antes'), findsOneWidget);
    await tester.tap(find.textContaining('Recordatorio · 30 minutos antes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivado').last);
    await tester.pumpAndSettle();
    expect(key.currentState!.reminderMinutes, 0);

    expect(find.text(l.chooseEventColor), findsOneWidget);
    final blueSwatch =
        find.byKey(ValueKey('event-color-${Colors.blue.toARGB32()}'));
    await tester.ensureVisible(blueSwatch);
    await tester.tap(blueSwatch);
    await tester.pumpAndSettle();
    expect(key.currentState!.selectedEventColor, Colors.blue.toARGB32());
    expect(find.byType(DropdownButtonFormField<Color>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick editor defers secondary settings to more options',
      (tester) async {
    var expandRequests = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: _FormHost(
          quickMode: true,
          onMoreOptions: () => expandRequests++,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('event-form-more-options')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-form-advanced-options')),
        findsNothing);
    expect(find.text('Fotos obligatorias'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('event-form-more-options')));
    expect(expandRequests, 1);
    expect(tester.takeException(), isNull);
  });
}
