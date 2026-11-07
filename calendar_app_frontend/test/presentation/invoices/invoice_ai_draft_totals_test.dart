import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/invoice/invoice_block.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('AI block-only draft shows calculated financial totals',
      (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InvoiceListItem(
          invoice: const Invoice(
            id: '',
            invoiceNumber: '',
            groupId: 'group-1',
            clientId: 'client-1',
            status: 'draft',
            blocks: [
              InvoiceBlock(
                type: InvoiceBlockType.item,
                description: 'Servicio creado con IA',
                qty: 2,
                unitPrice: 50,
                taxRate: 21,
              ),
            ],
          ),
          client: GroupClient(id: 'client-1', name: 'Cliente'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('100,00'), findsWidgets);
    expect(find.textContaining('21,00'), findsWidgets);
    expect(find.textContaining('121,00'), findsWidgets);
  });
}
