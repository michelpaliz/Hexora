import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_details_panel.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('right panel shows the contextual destination action',
      (tester) async {
    final notification = NotificationUser(
      id: 'draft-notification',
      senderId: 'sender',
      recipientId: 'recipient',
      titleKey: 'notification.recurringInvoice.draftCreated.title',
      messageKey: 'notification.recurringInvoice.draftCreated.message',
      fallbackTitle: 'Borrador de factura recurrente creado',
      fallbackMessage: 'Se ha creado un borrador de factura.',
      args: const {'invoiceId': 'invoice-1', 'clientName': 'Brisas'},
      timestamp: DateTime(2026, 10, 21),
      groupId: 'group-1',
      category: Category.billing,
    );
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: NotificationDetailsPanel(
          notification: notification,
          groupName: 'Group',
          onConfirm: null,
          onNegate: null,
          onOpen: () => opened = true,
          openLabel: 'Ver borrador',
          onMarkRead: null,
          onDelete: null,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Ver borrador'), findsOneWidget);
    await tester.tap(find.text('Ver borrador'));
    expect(opened, isTrue);
  });
}
