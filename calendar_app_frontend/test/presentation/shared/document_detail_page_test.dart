import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/widgets/receipt_detail_card.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_detail_page.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets('invoice detail page fits enlarged text without PDF placeholder',
      (tester) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.android),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!),
      home: DocumentDetailPage(
          title: 'Factura 324-26',
          child: InvoiceDetailSheet(
            fullPage: true,
            invoice: const Invoice(
                id: '',
                invoiceNumber: '324-26',
                groupId: 'g',
                clientId: 'c',
                status: 'issued',
                total: 733.26),
            client: GroupClient(
                id: 'c', name: 'FERCAMAR GESTIÓN ALMERÍA S.L.', isActive: true),
            billingProfile: null,
            group: Group(
                id: 'g',
                name: 'Grupo',
                ownerId: 'u',
                userRoles: const {},
                userIds: const [],
                createdTime: DateTime(2026),
                description: ''),
          )),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('PDF preview is only available on web.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('mobile receipt details are a full page at $scale text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var previewLoads = 0;
      var downloads = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DocumentDetailPage(
                              title: 'Recibo 324-26',
                              child: ReceiptDetailCard(
                                fullPage: true,
                                receipt: Receipt(
                                    id: 'r',
                                    groupId: 'g',
                                    clientId: 'c',
                                    receiptNumber: '324-26',
                                    status: 'issued',
                                    total: 733.26),
                                client: GroupClient(
                                    id: 'c',
                                    name: 'FERCAMAR GESTIÓN ALMERÍA S.L.',
                                    isActive: true),
                                billingProfile: null,
                                onEdit: () {},
                                onPreviewPdf: () {},
                                onDownloadPdf: () => downloads++,
                                onIssue: () {},
                                onDeleteDraft: () {},
                                onImportJson: () {},
                                onLoadInlinePdf: () async {
                                  previewLoads++;
                                  return null;
                                },
                              )))),
                  child: const Text('Abrir'),
                ))),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(previewLoads, 0);
      expect(find.text('PDF preview is only available on web.'), findsNothing);
      expect(tester.takeException(), isNull);
      final l =
          AppLocalizations.of(tester.element(find.byType(ReceiptDetailCard)))!;
      await tester.tap(find.text('${l.download} PDF'));
      expect(downloads, 1);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Abrir'), findsOneWidget);
    });
  }
}
