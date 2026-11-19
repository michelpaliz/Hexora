import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_details_panel.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
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
      await tester.tap(find.text('Eliminar'));
      expect(read, 1);
      expect(deleted, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
