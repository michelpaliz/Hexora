import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/group_undone_events_screen.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'pending_events_bulk_test.dart' as fixtures;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('mobile event titles, search and completed tab in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const pendingTitle =
          'Mantenimiento de jardín y piscina — Chalet Palmeras';
      const doneTitle = 'Mantenimiento piscina — Royal Playa';
      final repo = fixtures.Repo([
        fixtures.event('1').copyWith(title: pendingTitle),
        fixtures
            .event('2', owner: 'other')
            .copyWith(title: 'Revisión pendiente'),
        fixtures.event('3').copyWith(
            title: doneTitle, isDone: true, completedAt: DateTime(2026, 9, 1)),
      ]);
      final group = Group(
          id: 'group',
          name: 'Team',
          ownerId: 'me',
          userRoles: {},
          userIds: ['me'],
          createdTime: DateTime(2026),
          description: '');
      final user = User(
          id: 'me',
          name: 'Me',
          email: '',
          userName: 'me',
          groupIds: ['group'],
          emailVerified: true);
      await tester.pumpWidget(MultiProvider(
          providers: [
            Provider<IEventRepository>.value(value: repo),
            ChangeNotifierProvider<UserDomain>(create: (_) => fixtures.Users()),
          ],
          child: MaterialApp(
            theme: AppTheme.forPlatform(brightness,
                platform: TargetPlatform.android),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: GroupUndoneEventsScreen(
                group: group, user: user, role: GroupRole.admin),
          )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.text(pendingTitle)).maxLines, 3);
      expect(find.text('Completar'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no matching title');
      await tester.pumpAndSettle();
      expect(find.text(pendingTitle), findsNothing);
      expect(find.text('No hay eventos que coincidan con la búsqueda.'),
          findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Completados'));
      await tester.pumpAndSettle();
      expect(find.text(doneTitle), findsOneWidget);
      expect(tester.widget<Text>(find.text(doneTitle)).style?.decoration,
          isNot(TextDecoration.lineThrough));
      expect(find.text('Completar'), findsNothing);
      expect(find.textContaining('Marcar todos'), findsNothing);
      expect(find.textContaining('Completado:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
