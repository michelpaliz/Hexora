import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_details_panel.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('event details follow the Spanish locale', (tester) async {
    final notification = NotificationUser(
      id: 'event-notice',
      senderId: 'sender',
      recipientId: 'recipient',
      titleKey: 'notification.event.reminder.title',
      messageKey: 'notification.event.reminder.message',
      fallbackTitle: 'Event reminder',
      fallbackMessage: 'Event reminder message',
      args: {
        'eventId': 'event-1',
        'eventTitle': 'Visita de seguimiento',
        'eventType': 'work_visit',
        'status': 'pending',
        'createdByName': 'Michael',
        'startDate': DateTime(2026, 11, 16, 10).toIso8601String(),
        'endDate': DateTime(2026, 11, 16, 11, 45).toIso8601String(),
        'reminderTime': 30,
        'location': 'Sevilla',
        'description': 'Cita de demostración',
        'clientName': 'StudySpark Academy',
        'primaryServiceId': 'service-1',
      },
      timestamp: DateTime(2026, 11, 1),
      groupId: 'group-1',
      category: Category.eventReminder,
      type: NotificationType.reminder,
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: NotificationDetailsPanel(
          notification: notification,
          groupName: 'Grupo',
          onConfirm: null,
          onNegate: null,
          onMarkRead: null,
          onDelete: null,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('EVENTO'), findsOneWidget);
    expect(find.text('Creado por'), findsOneWidget);
    expect(find.text('Visita de trabajo'), findsWidgets);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('HORARIO'), findsOneWidget);
    expect(find.text('CONTENIDO'), findsOneWidget);
    expect(find.text('VISITA DE TRABAJO'), findsOneWidget);
    expect(find.text('Ver detalles'), findsOneWidget);
    expect(find.text('Created by'), findsNothing);
    expect(find.text('Schedule'), findsNothing);
  });

  for (final width in [360.0, 600.0]) {
    testWidgets('receipt details use payload and expose actions at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var read = 0;
      var deleted = 0;
      final notification = NotificationUser.fromJson({
        'id': 'receipt-notice',
        'fallbackTitle': 'Recibo emitido',
        'args': {
          'clientName': 'Cliente de prueba',
          'senderName': 'Michel',
          'amount': 120.8,
          'currency': 'EUR',
          'receiptNumber': 'R020.26',
        },
      });
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.windows),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: NotificationDetailsPanel(
          notification: notification,
          groupName: 'Grupo',
          onConfirm: null,
          onNegate: null,
          onMarkRead: () => read++,
          onDelete: () => deleted++,
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Cliente de prueba'), findsOneWidget);
      expect(find.textContaining('120,80'), findsOneWidget);
      expect(find.text('R020.26'), findsOneWidget);
      expect(find.text('Cobrado'), findsNothing);
      expect(find.text('Visita de trabajo'), findsNothing);
      await tester.ensureVisible(find.text('Marcar como leída'));
      await tester.tap(find.text('Marcar como leída'));
      // Delete lives in the "more actions" menu and asks for confirmation.
      await tester.tap(find.byTooltip('Más acciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(read, 1);
      expect(deleted, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
