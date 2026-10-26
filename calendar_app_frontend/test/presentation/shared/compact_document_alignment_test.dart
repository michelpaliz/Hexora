import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('invoice columns and status slots align in $brightness',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var opened = 0;
      await tester.pumpWidget(MaterialApp(
        theme:
            AppTheme.forPlatform(brightness, platform: TargetPlatform.windows)
                .copyWith(platform: TargetPlatform.windows),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: Column(children: [
          const CompactDocumentTableHeader(
            identityLabel: 'Factura',
            actionsWidth: 96,
            previewActionInFullView: false,
            showDeliveryColumn: true,
            visibleFinancialColumns: {
              HexoraFinancialColumn.date,
              HexoraFinancialColumn.taxableBase,
              HexoraFinancialColumn.vat,
              HexoraFinancialColumn.total,
              HexoraFinancialColumn.payment,
            },
          ),
          for (var i = 0; i < 3; i++)
            InvoiceListItem(
              invoice: Invoice(
                  id: '',
                  groupId: 'g',
                  clientId: 'c',
                  invoiceNumber: '36$i-26',
                  total: [36.30, 4395.42, 1234567.89][i],
                  paymentStatus: ['paid', 'partial', null][i],
                  status: 'issued',
                  deliveryStatus: 'sent',
                  deliveryChannel: 'email',
                  issueDate: DateTime(2026, 10, 26)),
              client: GroupClient(id: 'c', name: 'Cliente $i'),
              selected: i == 1,
              warning: i == 2,
              dateWarningTooltip:
                  i == 0 ? 'Change the draft date before issuing it.' : null,
              onTap: () => opened++,
              visibleFinancialColumns: const {
                HexoraFinancialColumn.date,
                HexoraFinancialColumn.taxableBase,
                HexoraFinancialColumn.vat,
                HexoraFinancialColumn.total,
                HexoraFinancialColumn.payment,
              },
            ),
        ])),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rows = find.byType(CompactDocumentRow);
      expect(find.text('Factura'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('document-actions-header')))
            .width,
        96,
      );
      expect(find.text('Pago'), findsOneWidget);
      expect(find.text('Pagada'), findsOneWidget);
      expect(find.text('Parcial'), findsOneWidget);
      expect(find.text('Sin información'), findsOneWidget);
      expect(find.byKey(const ValueKey('document-identity-column')),
          findsNWidgets(3));
      expect(find.byKey(const ValueKey('document-client-column')),
          findsNWidgets(3));
      expect(
        tester
            .getTopRight(find.byKey(const ValueKey('document-actions-header')))
            .dx,
        tester
            .getTopRight(
                find.byKey(const ValueKey('document-actions-column')).first)
            .dx,
      );
      for (final key in [
        'document-status-column',
        'document-delivery-column',
        'document-payment-column',
        'document-amount-column',
        'document-actions-column'
      ]) {
        final columns = find.byKey(ValueKey(key));
        expect(columns, findsNWidgets(3));
        final x = tester.getTopRight(columns.first).dx;
        for (var i = 1; i < 3; i++) {
          expect(tester.getTopRight(columns.at(i)).dx, x);
        }
      }
      expect(find.text('Enviada'), findsNWidgets(3));
      expect(find.text('26 oct 2026'), findsNWidgets(3));
      expect(
          find.byKey(const ValueKey('document-date-warning')), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(rows.at(i)).height,
            lessThanOrEqualTo(HexoraDocumentTokens.rowHeight));
      }
      expect(find.byTooltip('Requiere atención'), findsOneWidget);
      BorderDirectional border(int row) {
        final containers = tester.widgetList<Container>(find.descendant(
            of: find.byType(HexoraListRow).at(row),
            matching: find.byType(Container)));
        return (containers
                .firstWhere((c) => c.foregroundDecoration != null)
                .foregroundDecoration as BoxDecoration)
            .border! as BorderDirectional;
      }

      expect(border(0).start.color.a, 0);
      expect(border(1).start.color.a, 1);
      expect(border(0).bottom.width, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(border(0).top.color.a, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(opened, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(opened, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact invoice keeps status delivery and date in columns',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(820, 500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(children: [
          const CompactDocumentTableHeader(
            identityLabel: 'Factura',
            actionsWidth: 68,
            showDeliveryColumn: true,
            visibleFinancialColumns: {
              HexoraFinancialColumn.date,
              HexoraFinancialColumn.total,
              HexoraFinancialColumn.payment,
            },
          ),
          InvoiceListItem(
            invoice: Invoice(
              id: 'invoice-1',
              groupId: 'group-1',
              clientId: 'client-1',
              invoiceNumber: '382-26',
              total: 1548.03,
              paymentStatus: 'unpaid',
              status: 'issued',
              deliveryStatus: 'sent',
              issueDate: DateTime(2026, 10, 26),
            ),
            client: GroupClient(id: 'client-1', name: 'SueÃ±o de Denia IV'),
            onPreview: () {},
            visibleFinancialColumns: const {
              HexoraFinancialColumn.date,
              HexoraFinancialColumn.total,
              HexoraFinancialColumn.payment,
            },
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('document-status-column')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('document-delivery-column')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('document-payment-column')), findsOneWidget);
    expect(find.text('Emitida'), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('26 oct 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
