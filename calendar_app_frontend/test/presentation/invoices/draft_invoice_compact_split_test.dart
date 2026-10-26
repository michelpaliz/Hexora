import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('draft invoice stays compact in split view', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const clientName =
        'Comunidad de propietarios con un nombre especialmente largo';
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 480,
            child: DocumentWorkspaceScope(
              mode: DocumentViewMode.split,
              openPreviewDrawer: () {},
              child: InvoiceListItem(
                invoice: Invoice(
                  id: '',
                  invoiceNumber: '',
                  groupId: 'group-1',
                  clientId: 'client-1',
                  status: 'draft',
                  issueDate: DateTime(2026, 10, 26),
                  total: 1548.03,
                ),
                client: GroupClient(
                  id: 'client-1',
                  name: clientName,
                ),
                selected: true,
                dateWarningTooltip:
                    'Cambia la fecha del borrador antes de emitirlo.',
                onTap: () {},
                onPreview: () {},
                onEdit: () {},
                onIssue: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final row = find.byType(HexoraListRow);
    expect(tester.getSize(row).height, inInclusiveRange(56, 64));
    expect(find.text('Factura'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.byTooltip(clientName), findsOneWidget);
    expect(find.text('26 oct 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('document-date-warning')), findsOneWidget);
    expect(
      find.byTooltip('Cambia la fecha del borrador antes de emitirlo.'),
      findsOneWidget,
    );

    final amount = find.byKey(const ValueKey('document-amount-column'));
    final actions = find.byKey(const ValueKey('document-actions-column'));
    final status = find.byKey(const ValueKey('document-status-column'));
    expect(tester.getCenter(amount).dy, tester.getCenter(row).dy);
    expect(tester.getCenter(actions).dy, tester.getCenter(row).dy);
    expect(tester.getCenter(status).dy, tester.getCenter(row).dy);
    expect(tester.takeException(), isNull);
  });
}
