import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/widgets/notification_card.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('long notification header fits at $scale in $brightness',
          (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const title = 'Gastos bancarios detectados';
        final notification = NotificationUser.fromJson({
          'id': 'bank-fees',
          'fallbackTitle': title,
          'fallbackMessage':
              'Se detectaron 2 gastos bancarios por un total de 157,67 €.',
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 9))
              .toIso8601String(),
        });
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.forPlatform(brightness,
              platform: TargetPlatform.android),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
              body: ListView(children: [
            NotificationCard(notification: notification, onDelete: () {}),
          ])),
        ));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull);
        final timestamp = find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText().contains('hace 9 minutos') == true);
        expect(timestamp, findsOneWidget);
        expect(tester.getTopLeft(timestamp).dy,
            greaterThan(tester.getTopLeft(find.text(title)).dy));
      });
    }
  }
}
