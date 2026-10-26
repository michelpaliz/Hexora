import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  final group = Group(
    id: 'group',
    name: 'Grupo',
    ownerId: 'owner',
    userRoles: const {},
    userIds: const [],
    createdTime: DateTime(2026),
    description: '',
  );
  final client = GroupClient(
    id: 'client',
    name: 'Cliente',
    isActive: true,
  );

  Widget app(
    Invoice invoice, {
    VoidCallback? onOpenDeliveryRecord,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: AppTheme.forPlatform(
        brightness,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InvoiceDetailSheet(
          fullPage: true,
          invoice: invoice,
          client: client,
          billingProfile: null,
          group: group,
          onOpenDeliveryRecord: onOpenDeliveryRecord,
        ),
      ),
    );
  }

  testWidgets('preview payment and delivery statuses are read-only links',
      (tester) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var deliveryOpens = 0;

    await tester.pumpWidget(app(
      Invoice(
        id: '',
        invoiceNumber: '382-26',
        groupId: 'group',
        clientId: 'client',
        status: 'issued',
        total: 120,
        paymentStatus: 'paid',
        paymentMethod: 'transfer',
        paidAt: DateTime(2026, 10, 24, 10, 30),
        linkedEntriesCount: 1,
        linkedEntryId: 'entry',
        deliveryStatus: 'sent',
        sentAt: DateTime(2026, 10, 24, 11, 15),
        deliveryChannel: 'email',
      ),
      onOpenDeliveryRecord: () => deliveryOpens++,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('Editar pago'), findsNothing);
    expect(find.text('Transferencia'), findsOneWidget);
    expect(find.text('Ver pago'), findsOneWidget);
    expect(find.text('Ver envío'), findsOneWidget);

    await tester.ensureVisible(find.text('Ver envío'));
    await tester.tap(find.text('Ver envío'));
    expect(deliveryOpens, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview does not invent status destinations', (tester) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(
      const Invoice(
        id: '',
        invoiceNumber: 'draft',
        groupId: 'group',
        clientId: 'client',
        status: 'draft',
        total: 120,
        paymentStatus: 'unpaid',
        deliveryStatus: 'not_sent',
      ),
      brightness: Brightness.dark,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('Editar pago'), findsNothing);
    expect(find.text('Ver pago'), findsNothing);
    expect(find.text('Ver envío'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
