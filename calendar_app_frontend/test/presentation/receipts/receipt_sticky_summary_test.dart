import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/views/group_receipts_view.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('receipt totals stay visible below the scrolling table',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final receipts = List.generate(
      24,
      (index) => Receipt(
        id: 'receipt-$index',
        groupId: 'group',
        clientId: 'client',
        receiptNumber: 'R${index + 1}.26',
        status: 'issued',
        issueDate: DateTime(2026, 10, 28 - (index % 20)),
        subtotal: 100 + index,
        total: 121 + index,
        deliveryStatus: index == 0 ? 'sent' : 'not_sent',
      ),
    );
    final mode = ValueNotifier<DocumentViewMode?>(DocumentViewMode.list);
    addTearDown(mode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupReceiptsView(
            drafts: const [],
            receipts: receipts,
            clients: [GroupClient(id: 'client', name: 'Cliente')],
            billingProfile: null,
            selectedReceipt: null,
            onSelectReceipt: (_) {},
            onCreateReceipt: () {},
            onEditReceipt: (_) {},
            onIssueReceipt: (_) {},
            onMarkReceiptSent: (_) {},
            onMarkReceiptUnsent: (_) {},
            onDeleteReceipt: (_) {},
            onPreviewPdf: (_) async {},
            onDownloadPdf: (_) {},
            onImportJson: (_) {},
            onLoadInlinePdf: (_) async => null,
            initialTabIndex: 1,
            showHeaderTabs: false,
            modeNotifier: mode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final footerFinder = find.byKey(
      const ValueKey('receipt-aligned-financial-summary'),
    );
    expect(footerFinder, findsOneWidget);
    final footer = tester.widget<CompactDocumentFinancialFooter>(footerFinder);
    expect(footer.countLabel, '24 recibos');
    expect(footer.taxableBaseValue, contains('2.676,00'));
    expect(footer.totalValue, contains('3.180,00'));
    expect(find.text('Envío'), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('No enviado'), findsWidgets);

    final initialTop = tester.getTopLeft(footerFinder).dy;
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(footerFinder).dy, initialTop);
    expect(tester.takeException(), isNull);
  });
}
