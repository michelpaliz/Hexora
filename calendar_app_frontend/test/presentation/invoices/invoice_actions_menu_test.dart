import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/hexora_popup_menu.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Future<void> pumpInvoice(
    WidgetTester tester, {
    VoidCallback? onEdit,
    VoidCallback? onIssue,
    VoidCallback? onDelete,
    VoidCallback? onLinkInvoice,
  }) async {
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
        body: DocumentWorkspaceScope(
          mode: DocumentViewMode.list,
          openPreviewDrawer: () {},
          child: InvoiceListItem(
            invoice: const Invoice(
              id: 'invoice-1',
              invoiceNumber: 'BORRADOR',
              groupId: 'group-1',
              clientId: 'client-1',
              status: 'draft',
              total: 123.45,
            ),
            client: GroupClient(id: 'client-1', name: 'Cliente'),
            onTap: () {},
            onPreview: () {},
            onEdit: onEdit,
            onIssue: onIssue,
            onDelete: onDelete,
            onLinkInvoice: onLinkInvoice,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('draft actions use the compact shared popup hierarchy',
      (tester) async {
    await pumpInvoice(
      tester,
      onEdit: () {},
      onIssue: () {},
      onDelete: () {},
    );

    final popup = tester.widget<PopupMenuButton<int>>(
      find.byType(PopupMenuButton<int>),
    );
    expect(popup.constraints?.minWidth, 200);
    expect(popup.constraints?.maxWidth, 220);

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Descargar PDF'), findsOneWidget);
    expect(find.text('Emitir factura'), findsOneWidget);
    expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
    expect(find.byType(HexoraPopupMenuDivider), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('unavailable status actions are omitted', (tester) async {
    await pumpInvoice(tester);

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();

    expect(find.text('Descargar PDF'), findsOneWidget);
    expect(find.text('Emitir factura'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
  });

  testWidgets('invoice linking reuses the compact actions menu',
      (tester) async {
    var linked = false;
    await pumpInvoice(tester, onLinkInvoice: () => linked = true);

    await tester.tap(find.byType(PopupMenuButton<int>));
    await tester.pumpAndSettle();

    expect(find.text('Vincular factura'), findsOneWidget);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);

    await tester.tap(find.text('Vincular factura'));
    await tester.pumpAndSettle();
    expect(linked, isTrue);
  });
}
