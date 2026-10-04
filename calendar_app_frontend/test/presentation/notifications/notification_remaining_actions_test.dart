import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_payload_helper.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/widgets/notification_card.dart';

void main() {
  test('ZIP routing normalizes job type and both status fields', () {
    final n = NotificationUser.fromJson({
      'args': {'jobType': ' INVOICE_ZIP ', 'status': 'READY'}
    });
    expect(isInvoiceZipNotification(n), isTrue);
    expect(notificationDownloadStatus(n), 'ready');
    final failed = NotificationUser.fromJson({
      'args': {
        'jobType': 'invoice_zip',
        'downloadStatus': ' Failed ',
        'status': 'ready'
      }
    });
    expect(notificationDownloadStatus(failed), 'failed');
    expect(
        isInvoiceZipNotification(NotificationUser.fromJson({
          'args': {'jobType': 'OCR_IMPORT'}
        })),
        isFalse);
  });
  for (final invite in [false, true]) {
    testWidgets('invitation controls only appear for invitations ($invite)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var accepted = 0;
      var declined = 0;
      final n = NotificationUser.fromJson({
        'id': 'notice',
        'category':
            (invite ? Category.groupInvitation : Category.message).index,
        'fallbackTitle': 'Aviso',
        'questionsAndAnswers': {'question': 'answer'},
      });
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: ListView(children: [
          NotificationCard(
              notification: n,
              onDelete: () {},
              onConfirm: () => accepted++,
              onNegate: () => declined++)
        ])),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Aceptar invitación'),
          invite ? findsOneWidget : findsNothing);
      expect(find.text('Rechazar'), invite ? findsOneWidget : findsNothing);
      if (invite) {
        await tester.tap(find.text('Aceptar invitación'));
        await tester.tap(find.text('Rechazar'));
        expect(accepted, 1);
        expect(declined, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
