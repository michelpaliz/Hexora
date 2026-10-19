import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('invoice columns and status slots align in $brightness',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 700);
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
          for (var i = 0; i < 3; i++)
            InvoiceListItem(
              invoice: Invoice(
                  id: '',
                  groupId: 'g',
                  clientId: 'c',
                  invoiceNumber: '36$i-26',
                  total: [36.30, 4395.42, 1234567.89][i],
                  status: 'issued',
                  deliveryStatus: 'sent',
                  deliveryChannel: 'email'),
              client: GroupClient(id: 'c', name: 'Cliente $i'),
              selected: i == 1,
              warning: i == 2,
              onTap: () => opened++,
            ),
        ])),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rows = find.byType(CompactDocumentRow);
      for (final key in [
        'document-status-column',
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
      // Secondary states (payment, delivery, reconciliation) sit behind the
      // info icon in the status column.
      final links = find.byIcon(Icons.info_outline_rounded);
      expect(links, findsNWidgets(3));
      expect(
          tester.getCenter(links.at(0)).dx, tester.getCenter(links.at(2)).dx);
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(rows.at(i)).height, lessThanOrEqualTo(HexoraDocumentTokens.rowHeight));
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
      expect(tester.takeException(), isNull);
    });
  }
}
