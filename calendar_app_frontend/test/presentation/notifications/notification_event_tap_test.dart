import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/widgets/notification_card.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('mobile event title opens destination and arrow expands details',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opens = 0;
    final notification = NotificationUser.fromJson({
      'id': 'notice',
      'titleKey': 'notification.event.updated.title',
      'fallbackMessage': 'Detailed event information',
      'args': {'eventId': 'event-123', 'eventTitle': 'Pool maintenance'},
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.android),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!),
      home: Scaffold(
          body: ListView(children: [
        NotificationCard(
          notification: notification,
          onDelete: () {},
          onTap: () => opens++,
          onOpenEvent: (id, _) {
            expect(id, 'event-123');
            opens++;
          },
        )
      ])),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Pool maintenance'));
    await tester.pumpAndSettle();
    expect(opens, 1);
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(opens, 1);
    await tester.ensureVisible(find.byTooltip('Open event'));
    await tester.tap(find.byTooltip('Open event'));
    expect(opens, 2);
    expect(tester.takeException(), isNull);
  });
}
