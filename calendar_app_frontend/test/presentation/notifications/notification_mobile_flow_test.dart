import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/workspace/sections/notifications/widgets/mobile_notification.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
        'notification list to document details at large text in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const client = 'MARÍA CONCEPCIÓN MONZÓN ARAMBURU Y ASOCIADOS';
      final notification = NotificationUser(
          id: 'notification-1',
          senderId: 'sender',
          recipientId: 'user',
          titleKey: 'notification.invoice.issued.title',
          messageKey: '',
          fallbackTitle: 'Factura emitida',
          fallbackMessage: 'Factura 32-26 · $client',
          args: const {
            'documentId': 'invoice-1',
            'documentType': 'invoice',
            'documentNumber': '32-26',
            'clientName': client,
            'amount': 36.30,
            'currency': 'EUR'
          },
          timestamp: DateTime(2026, 9, 6),
          groupId: 'group',
          category: Category.billing);
      NotificationDetailAction? result;
      await tester.pumpWidget(MaterialApp(
        theme:
            AppTheme.forPlatform(brightness, platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: Scaffold(
            body: Builder(
                builder: (context) => ListView(children: [
                      MobileNotificationTile(
                          notification: notification,
                          onTap: () async {
                            result = await Navigator.of(context)
                                .push<NotificationDetailAction>(
                                    MaterialPageRoute(
                                        builder: (_) => NotificationDetailPage(
                                            notification: notification,
                                            openLabel: 'Ver documento')));
                          }),
                    ]))),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(MobileNotificationTile));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationDetailPage), findsOneWidget);
      expect(find.text(client), findsOneWidget);
      expect(notification.isRead, isFalse);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Más opciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar notificación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationDetailPage), findsOneWidget);
      expect(result, isNull);
      await tester.tap(find.text('Ver documento'));
      await tester.pumpAndSettle();
      expect(result, NotificationDetailAction.open);
      expect(find.byType(MobileNotificationTile), findsOneWidget);
    });
  }

  for (final expected in const [
    NotificationDetailAction.confirm,
    NotificationDetailAction.decline,
    NotificationDetailAction.markRead,
    NotificationDetailAction.delete,
  ]) {
    testWidgets('notification detail returns the $expected action',
        (tester) async {
      final notification = NotificationUser(
        id: 'invitation-1',
        senderId: 'sender',
        recipientId: 'user',
        titleKey: '',
        messageKey: '',
        fallbackTitle: 'Group invitation',
        fallbackMessage: 'You were invited to a group',
        args: const {},
        timestamp: DateTime(2026, 9, 21),
        groupId: 'group',
        category: Category.groupInvitation,
      );
      NotificationDetailAction? result;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await Navigator.of(context)
                    .push<NotificationDetailAction>(MaterialPageRoute(
                  builder: (_) => NotificationDetailPage(
                    notification: notification,
                  ),
                ));
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      switch (expected) {
        case NotificationDetailAction.confirm:
          await tester.tap(find.text('Confirm'));
          break;
        case NotificationDetailAction.decline:
          await tester.tap(find.text('Cancel'));
          break;
        case NotificationDetailAction.markRead:
          await tester.tap(find.byTooltip('More options'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Mark as read'));
          break;
        case NotificationDetailAction.delete:
          await tester.tap(find.byTooltip('More options'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete notification'));
          await tester.pumpAndSettle();
          await tester.tap(find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Confirm'),
          ));
          break;
        case NotificationDetailAction.open:
          fail('Open is covered by the document notification test.');
      }
      await tester.pumpAndSettle();

      expect(result, expected);
      expect(find.byType(NotificationDetailPage), findsNothing);
    });
  }
}
