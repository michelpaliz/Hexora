import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/client_detail_panel.dart';
import 'package:hexora/presentation/shared/widgets/client_property_image.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('client detail uses compact header and one period menu',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = GroupClient(id: 'client-1', name: 'Belman');
    final invoice = Invoice(
      id: 'invoice-1',
      invoiceNumber: '361-26',
      groupId: 'group-1',
      clientId: client.id,
      status: 'issued',
      issueDate: DateTime(2026, 10, 13),
      total: 157.30,
      deliveryStatus: 'sent',
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
        body: ClientDetailPanel(
          groupId: 'group-1',
          clients: [client],
          selectedClient: client,
          issuedInvoices: [invoice],
          draftInvoices: const [],
          entityOptions: const [],
          propertyOptions: const [],
          assignBusy: false,
          onEditSelectedClient: () {},
          onCreateInvoice: () {},
          onCreateReceipt: () {},
          onOpenInvoiceDetail: (_) {},
          onDeleteInvoice: (_) {},
          onDownloadVisibleInvoices: (_) async {},
          onApplyClassification: ({entityType, propertyKind}) async {},
        ),
      ),
    ));
    await tester.pump();

    expect(
        tester.getSize(find.byType(ClientPropertyImage)), const Size(40, 40));
    expect(find.byKey(const ValueKey('client-document-period-menu')),
        findsOneWidget);
    expect(find.text('ZIP (1)'), findsOneWidget);
    expect(find.text('30 días'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('client-document-period-menu')));
    await tester.pumpAndSettle();

    expect(find.text('30 días'), findsOneWidget);
    expect(find.text('3 meses'), findsOneWidget);
    expect(find.text('Personalizado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
