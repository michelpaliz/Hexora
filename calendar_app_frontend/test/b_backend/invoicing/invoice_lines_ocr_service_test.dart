import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_models.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_service.dart';

void main() {
  group('createInvoiceLinesBulk', () {
    test('continues after failures and returns partial results', () async {
      final calls = <int>[];
      final service = InvoiceLinesOcrService();

      final draftLines = <OcrExtractedLineDraft>[
        const OcrExtractedLineDraft(
          position: 2,
          description: 'Second',
          quantity: 1,
          unitPrice: 30,
          taxRate: 21,
          lineSubtotal: 30,
          lineTax: 6.3,
          lineTotal: 36.3,
          sourceText: '',
        ),
        const OcrExtractedLineDraft(
          position: 1,
          description: 'First',
          quantity: 1,
          unitPrice: 20,
          taxRate: 21,
          lineSubtotal: 20,
          lineTax: 4.2,
          lineTotal: 24.2,
          sourceText: '',
        ),
      ];

      final result = await service.createInvoiceLinesBulk(
        'inv-1',
        draftLines,
        createFn: (String invoiceId, InvoiceLine line) async {
          calls.add(line.position);
          if (line.position == 2) {
            throw Exception('save failed');
          }
          return line;
        },
      );

      expect(calls, [1, 2]);
      expect(result.total, 2);
      expect(result.savedCount, 1);
      expect(result.failedCount, 1);
      expect(result.success.single.position, 1);
      expect(result.failed.single.line.position, 2);
      expect(result.failed.single.reason, contains('save failed'));
    });
  });
}
