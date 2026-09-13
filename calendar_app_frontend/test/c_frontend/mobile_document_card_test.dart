import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_list_item.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/mobile_document_card.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('documents share readable mobile cards in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client =
          GroupClient(id: 'client', name: 'MARÍA CONCEPCIÓN MONZÓN ARAMBURU');
      var opened = 0;
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
            body: SingleChildScrollView(
                child: Column(children: [
          InvoiceListItem(
              mobile: true,
              invoice: const Invoice(
                  id: 'invoice',
                  invoiceNumber: '32-26',
                  groupId: 'group',
                  clientId: 'client',
                  total: 36.30,
                  deliveryStatus: 'sent',
                  status: 'issued'),
              client: client,
              onTap: () => opened++),
          ReceiptListItem(
              receipt: const Receipt(
                  id: 'receipt',
                  groupId: 'group',
                  clientId: 'client',
                  receiptNumber: 'R32-26',
                  status: 'issued',
                  total: 36.30),
              client: client,
              onTap: () => opened++),
          MobileDocumentCard(
              title: client.name,
              amount: '36,30 €',
              metadata: 'P32-26 · 11 sept 2026',
              isDraft: true,
              statusLabel: 'Borrador',
              onTap: () => opened++),
        ]))),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(MobileDocumentCard), findsNWidgets(3));
      expect(find.text('Enviada'), findsOneWidget);
      expect(find.text('No enviado'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 3; i++) {
        final card = find.byType(MobileDocumentCard).at(i);
        await tester.ensureVisible(card);
        await tester
            .tap(find.descendant(of: card, matching: find.text(client.name)));
        await tester.pumpAndSettle();
      }
      expect(opened, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
