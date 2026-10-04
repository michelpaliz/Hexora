import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/widgets/section_card_work_type.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/assigned_users_section.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/date_time_section.dart';
import 'package:hexora/theme/themes/app_theme.dart';

User makeUser(String id, String name) => User(
      id: id,
      name: name,
      email: '$id@example.test',
      userName: id,
      groupIds: const [],
      emailVerified: true,
    );

void main() {
  testWidgets('delegate visit selects a worker directly on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final owner = makeUser('owner', 'Owner');
    final worker = makeUser('worker', 'Alex Worker');
    List<User> selected = [];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.android,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => AssignedUsersSection(
            title: 'Delegar visita',
            cardBuilder: SectionCard.new,
            usersAvailable: [owner, worker],
            initiallySelected: selected,
            excludeUserId: owner.id,
            onSelectedUsersChanged: (users) => setState(() => selected = users),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(AssignedUsersSection));
    await tester.pumpAndSettle();
    expect(find.text('Alex Worker'), findsOneWidget);
    expect(find.text('Owner'), findsNothing);
    await tester.tap(find.text('Alex Worker'));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l.confirm));
    await tester.pumpAndSettle();

    expect(selected.map((user) => user.id), ['worker']);
    expect(find.text('Alex Worker'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('start and end rows fit a narrow phone with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var startTaps = 0;
    var endTaps = 0;
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
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: Scaffold(
        body: DateTimeSection(
          title: 'Horario',
          cardBuilder: SectionCard.new,
          startDate: DateTime(2026, 9, 18, 9),
          endDate: DateTime(2026, 9, 18, 10),
          onStartTap: () => startTaps++,
          onEndTap: () => endTaps++,
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Fecha de inicio:'));
    await tester.tap(find.text('Fecha de fin:'));
    expect(startTaps, 1);
    expect(endTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
