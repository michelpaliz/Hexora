import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_normalizer.dart';

void main() {
  group('normalizeExtractedLine', () {
    test('applies defaults and recomputes totals', () {
      final line = normalizeExtractedLine(
        {
          'description': '   ',
          'quantity': '2',
          'unitPrice': '10.5',
          'taxRate': 21,
          'sourceText': 'raw source',
        },
        0,
      );

      expect(line.position, 1);
      expect(line.description, 'Linea OCR 1');
      expect(line.quantity, 2);
      expect(line.unitPrice, 10.5);
      expect(line.taxRate, 21);
      expect(line.lineSubtotal, closeTo(21, 0.0001));
      expect(line.lineTax, closeTo(4.41, 0.0001));
      expect(line.lineTotal, closeTo(25.41, 0.0001));
      expect(line.sourceText, 'raw source');
    });
  });

  group('normalizeExtractResponse', () {
    test('normalizes response defaults safely', () {
      final response = normalizeExtractResponse({
        'ok': true,
        'invoiceId': 'inv-1',
        'confidence': 'bad-value',
        'draftLines': [
          {
            'description': 'Consulting',
            'quantity': 1,
            'unitPrice': 100,
            'taxRate': 21,
          },
        ],
        'warnings': ['warn-a', '', null],
      });

      expect(response.ok, true);
      expect(response.invoiceId, 'inv-1');
      expect(response.confidence, isNull);
      expect(response.lineCount, 1);
      expect(response.rawText, '');
      expect(response.warnings, ['warn-a']);
      expect(response.draftLines, hasLength(1));
      expect(response.draftLines.first.description, 'Consulting');
    });
  });
}
