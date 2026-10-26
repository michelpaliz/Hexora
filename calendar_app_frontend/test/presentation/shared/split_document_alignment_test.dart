import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';

void main() {
  testWidgets('split rows align total and actions with the header',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DocumentWorkspaceScope(
          mode: DocumentViewMode.split,
          openPreviewDrawer: () {},
          child: const SizedBox(
            width: 900,
            child: Column(
              children: [
                CompactDocumentTableHeader(
                  identityLabel: 'Factura',
                  visibleFinancialColumns: {
                    HexoraFinancialColumn.date,
                    HexoraFinancialColumn.total,
                  },
                  showDeliveryColumn: true,
                  actionsWidth: 68,
                ),
                CompactDocumentRow(
                  title: '338-26',
                  metadata: 'Cliente',
                  amount: '255,00 €',
                  date: null,
                  status: Text('Emitida'),
                  delivery: Text('No enviada'),
                  showDeliveryColumn: true,
                  previewLabel: 'Vista previa',
                  onPreview: _noop,
                  quickActionSlots: 1,
                  quickActions: [
                    CompactDocumentQuickAction(
                      icon: Icons.visibility_outlined,
                      tooltip: 'Vista previa',
                      onPressed: _noop,
                      opensPreviewDrawer: true,
                    ),
                  ],
                  actions: [CompactDocumentAction('Más', _noop)],
                  visibleFinancialColumns: {
                    HexoraFinancialColumn.date,
                    HexoraFinancialColumn.total,
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ));

    final header = find.byKey(const ValueKey('document-actions-header'));
    final total = find.byKey(const ValueKey('document-amount-column'));
    final actions = find.byKey(const ValueKey('document-actions-column'));
    expect(tester.getSize(header).width, 32);
    expect(tester.getSize(actions).width, 32);
    expect(tester.getTopLeft(actions).dx - tester.getTopRight(total).dx, 16);
    expect(tester.getCenter(find.byType(PopupMenuButton<int>)).dx,
        tester.getCenter(header).dx);
  });
}

void _noop() {}
