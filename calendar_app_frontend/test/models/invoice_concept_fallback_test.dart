import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/invoice/invoice.dart';

void main() {
  Invoice parse(Map<String, dynamic> extra) => Invoice.fromJson({
        'id': 'invoice-1',
        'invoiceNumber': '370-26',
        'groupId': 'group-1',
        'clientId': 'client-1',
        ...extra,
      });

  test('keeps line descriptions for invoice history concepts', () {
    final invoice = parse({
      'lines': [
        {'description': 'Mantenimiento de jardines'},
      ],
    });

    expect(invoice.lines.single.description, 'Mantenimiento de jardines');
    expect(invoice.conceptSummaries, isEmpty);
  });

  test('builds fallback lines from summary concepts returned by list endpoints',
      () {
    final invoice = parse({
      'concepts': ['Limpieza de piscina', 'Revisión de riego'],
    });

    expect(
        invoice.conceptSummaries, ['Limpieza de piscina', 'Revisión de riego']);
    expect(invoice.lines.map((line) => line.description),
        ['Limpieza de piscina', 'Revisión de riego']);
  });

  test('does not invent a concept when invoice has no descriptions', () {
    final invoice = parse({});

    expect(invoice.lines, isEmpty);
    expect(invoice.blocks, isEmpty);
    expect(invoice.conceptSummaries, isEmpty);
  });
}
