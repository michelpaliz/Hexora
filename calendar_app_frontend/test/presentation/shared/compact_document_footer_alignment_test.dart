import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('financial footer follows the shared invoice column layout',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var columns = <HexoraFinancialColumn>{
      HexoraFinancialColumn.date,
      HexoraFinancialColumn.concept,
      HexoraFinancialColumn.taxableBase,
      HexoraFinancialColumn.vat,
      HexoraFinancialColumn.total,
      HexoraFinancialColumn.payment,
    };
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                children: [
                  CompactDocumentTableHeader(
                    identityLabel: 'Factura',
                    visibleFinancialColumns: columns,
                    actionsWidth: 68,
                    showDeliveryColumn: true,
                    invoiceColumnOrder: true,
                    preferWideClient: true,
                    headerBuilder: (_, column, __, width, ___) => SizedBox(
                      key: ValueKey('header-${column.name}'),
                      width: width,
                    ),
                  ),
                  CompactDocumentFinancialFooter(
                    countLabel: '400 facturas',
                    taxableBaseValue: '10.000,00 €',
                    vatValue: '2.100,00 €',
                    totalValue: '12.100,00 €',
                    visibleFinancialColumns: columns,
                    actionsWidth: 68,
                    showDeliveryColumn: true,
                    invoiceColumnOrder: true,
                    preferWideClient: true,
                    compactFallback: const SizedBox(
                      key: ValueKey('compact-footer'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    void expectAligned(String headerKey, String footerKey) {
      final header = tester.getRect(find.byKey(ValueKey(headerKey)));
      final footer = tester.getRect(find.byKey(ValueKey(footerKey)));
      expect(footer.left, closeTo(header.left, .01));
      expect(footer.right, closeTo(header.right, .01));
    }

    expectAligned('header-taxableBase', 'invoice-footer-taxable-base');
    expectAligned('header-vat', 'invoice-footer-vat');
    expectAligned('header-total', 'invoice-footer-total');
    expect(find.text('400 facturas'), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-footer')), findsNothing);

    update(() => columns = {...columns}..remove(HexoraFinancialColumn.vat));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('header-vat')), findsNothing);
    expect(find.byKey(const ValueKey('invoice-footer-vat')), findsNothing);
    expectAligned('header-total', 'invoice-footer-total');

    tester.view.physicalSize = const Size(900, 500);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('compact-footer')), findsOneWidget);
    expect(find.byKey(const ValueKey('invoice-footer-total')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
