import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/invoice/invoice_block.dart';
import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoice_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';

void main() {
  test('invoice block draft parses localized European amounts', () {
    final draft = InvoiceBlockDraft(
      type: InvoiceBlockType.item,
      description: 'Servicio de conserjeria',
      qty: '1',
      unitPrice: '2.359,60',
      discountRate: '0',
      taxRate: '21',
    );
    addTearDown(draft.dispose);

    expect(draft.unitPrice, 2359.60);
    expect(draft.toBlock().unitPrice, 2359.60);
  });
}
