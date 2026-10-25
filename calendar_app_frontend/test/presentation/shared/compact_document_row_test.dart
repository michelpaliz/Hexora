import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/widgets/receipt_list_item.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [400.0, 700.0, 900.0]) {
      testWidgets(
          'compact financial rows $brightness width $width retain actions',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1200, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final calls = <String>[];
        final client = GroupClient(
            id: 'client', name: 'Las Alondras Playa comunidad de propietarios');
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.forPlatform(brightness,
              platform: TargetPlatform.windows),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(width < 500 ? 1.5 : 1)),
              child: child!),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                      width: width,
                      child: ListView(children: [
                        const CompactDocumentMonthHeading(
                            label: 'Septiembre de 2026'),
                        InvoiceListItem(
                            invoice: Invoice(
                                id: '',
                                invoiceNumber: '336-26',
                                groupId: 'group',
                                clientId: 'client',
                                status: 'issued',
                                total: 714.48,
                                issueDate: DateTime(2026, 9, 26)),
                            client: client,
                            onTap: () => calls.add('details'),
                            onEdit: () => calls.add('edit'),
                            onIssue: () => calls.add('issue'),
                            onDelete: () => calls.add('delete'),
                            onInspectRecurrence: () => calls.add('recurrence')),
                        ReceiptListItem(
                            receipt: const Receipt(
                                id: 'receipt',
                                groupId: 'group',
                                clientId: 'client',
                                status: 'issued',
                                total: 123),
                            client: client,
                            onDownload: () => calls.add('download'),
                            onMarkSent: () => calls.add('sent'),
                            onDelete: () => calls.add('receiptDelete')),
                      ])))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (width >= 650) {
          expect(tester.getSize(find.byType(CompactDocumentRow).first).height,
              lessThanOrEqualTo(HexoraDocumentTokens.rowHeight));
          expect(
              tester.getSize(find.byType(CompactDocumentMonthHeading)).height,
              lessThanOrEqualTo(24));
        }
        final l =
            AppLocalizations.of(tester.element(find.byType(InvoiceListItem)))!;
        Future<void> select(int row, String label) async {
          await tester.tap(find.descendant(
              of: find.byType(CompactDocumentRow).at(row),
              matching: find.byType(PopupMenuButton<int>)));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
        }

        // The row is the only primary details action. Edit and download stay
        // visible, while delivery tracking and other secondary actions remain
        // in the overflow menu.
        await tester.tap(find.text('336-26'));
        await tester.pumpAndSettle();
        expect(calls.where((call) => call == 'details').length, 1);
        await tester.tap(find.descendant(
            of: find.byType(CompactDocumentRow).at(0),
            matching: find.byTooltip(l.edit)));
        expect(calls.where((call) => call == 'details').length, 1);
        await tester.tap(find.descendant(
            of: find.byType(CompactDocumentRow).at(1),
            matching: find.byTooltip(l.download)));
        expect(
            find.descendant(
                of: find.byType(CompactDocumentRow).at(0),
                matching: find.byIcon(Icons.visibility_outlined)),
            findsNothing);
        await select(0, l.invoiceIssueCta);
        await select(0, 'Ver recurrencia');
        await select(0, l.delete);
        await select(0, 'Seguimiento de entrega');
        expect(find.textContaining(l.invoiceLinesTitle), findsOneWidget);
        await select(0, 'Ocultar seguimiento');
        expect(find.textContaining(l.invoiceLinesTitle), findsNothing);
        expect(calls.where((call) => call == 'details').length, 1);
        await select(1, 'Marcar como enviado');
        await select(1, l.delete);
        expect(
            calls,
            containsAll([
              'edit',
              'details',
              'issue',
              'recurrence',
              'delete',
              'download',
              'sent',
              'receiptDelete'
            ]));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
