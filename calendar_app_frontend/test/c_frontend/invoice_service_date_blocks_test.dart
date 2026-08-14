import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/a-models/invoice/invoice_block_payload.dart';

void main() {
  test('saved blocks include date headers between their corresponding items',
      () {
    final payload = buildInvoiceBlocksPayload(const [
      InvoiceBlock(
        type: InvoiceBlockType.item,
        description: 'B30: Arreglar mampara',
        serviceDate: '06-07-2026',
      ),
      InvoiceBlock(
        type: InvoiceBlockType.item,
        description: 'B25: Cambiar pulsador',
        serviceDate: '06/07/2026',
      ),
      InvoiceBlock(
        type: InvoiceBlockType.item,
        description: 'C9: Arreglar grifo',
        serviceDate: '07-07-2026',
      ),
    ]).map((block) => block.toJson()).toList();

    expect(payload, [
      {'type': 'date', 'level': 0, 'title': '06/07/2026'},
      {
        'type': 'item',
        'serviceDate': '2026-07-06',
        'description': 'B30: Arreglar mampara',
      },
      {
        'type': 'item',
        'serviceDate': '2026-07-06',
        'description': 'B25: Cambiar pulsador',
      },
      {'type': 'date', 'level': 0, 'title': '07/07/2026'},
      {
        'type': 'item',
        'serviceDate': '2026-07-07',
        'description': 'C9: Arreglar grifo',
      },
    ]);
  });

  test('legacy date blocks become line service dates in the editor', () {
    final blocks = invoiceBlocksForEditor(const [
      InvoiceBlock(
        type: InvoiceBlockType.date,
        title: '06/07/2026',
        level: 0,
      ),
      InvoiceBlock(
        type: InvoiceBlockType.item,
        description: 'B30: Arreglar mampara',
      ),
    ]);

    expect(blocks, hasLength(1));
    expect(blocks.single.type, InvoiceBlockType.item);
    expect(blocks.single.serviceDate, '2026-07-06');
  });
}
