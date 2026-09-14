import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/group_model/event/model/event.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/presentation/utils/image/user_image/widgets/user_status_row.dart';
import 'package:hexora/presentation/utils/image/user_image/widgets/pulsing_ring_avatar.dart';
import 'package:hexora/presentation/screens/calendar/screens/event/screen/events_in_calendar/event_display_manager/widgets/schedule_card_view.dart';
import 'package:hexora/presentation/screens/events/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

Widget app(Widget home, Brightness brightness, {bool reduceMotion = false}) =>
    MaterialApp(
        theme:
            AppTheme.forPlatform(brightness, platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
                padding: const EdgeInsets.only(top: 28, bottom: 24),
                disableAnimations: reduceMotion),
            child: child!),
        home: home);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('agenda opens safe mobile details and returns in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final event = Event(
          id: 'event',
          ownerId: '',
          startDate: DateTime(2026, 8, 27, 10),
          endDate: DateTime(2026, 8, 27, 11, 30),
          title: 'mantenimiento jardín y piscina – Las Alondras Playa',
          type: 'work_visit',
          status: 'pending',
          description: 'Descripción del trabajo');
      await tester.pumpWidget(app(
          Scaffold(
              body: Builder(
                  builder: (context) => Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                          width: 270,
                          height: 220,
                          child: ScheduleCardView(
                              event: event,
                              contextRef: context,
                              textColor: Colors.black,
                              appointment: event,
                              cardColor: Colors.orange,
                              actionManager: null,
                              userRole: 'member'))))),
          brightness));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(event.title));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.getTopLeft(find.text(event.title)).dy, greaterThan(28));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleCardView), findsOneWidget);
    });
  }

  testWidgets('presence pulse stops offline and respects reduced motion',
      (tester) async {
    Widget row(bool online) => Scaffold(
            body: UserStatusRow(userList: [
          UserPresence(
              userId: 'user',
              userName: 'long_connected_username',
              photoUrl: '',
              isOnline: online,
              role: UserRole.member)
        ]));
    await tester.pumpWidget(app(row(true), Brightness.light));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        tester
            .widget<PulsingRingAvatar>(find.byType(PulsingRingAvatar))
            .isOnline,
        isTrue);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(app(row(false), Brightness.light));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PulsingRingAvatar>(find.byType(PulsingRingAvatar))
            .isOnline,
        isFalse);
    await tester
        .pumpWidget(app(row(true), Brightness.light, reduceMotion: true));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
