import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/services/invoicing/filtered_invoices_excel.dart';

void main() {
  const selected = Invoice(
    id: 'selected-invoice',
    invoiceNumber: '001-26',
    groupId: 'group',
    clientId: 'customer',
    status: 'issued',
    currency: 'EUR',
    subtotal: 100,
    taxTotal: 21,
    total: 121,
  );

  String worksheet(List<Invoice> invoices, {String client = 'Customer'}) {
    final bytes = buildFilteredInvoicesExcel(
      invoices: invoices,
      clientNames: {'customer': client},
    );
    final zip = ZipDecoder().decodeBytes(bytes, verify: true);
    expect(zip.findFile('[Content_Types].xml'), isNotNull);
    expect(zip.findFile('_rels/.rels'), isNotNull);
    expect(zip.findFile('xl/_rels/workbook.xml.rels'), isNotNull);
    expect(zip.findFile('xl/styles.xml'), isNotNull);
    return utf8.decode(zip.findFile('xl/worksheets/sheet1.xml')!.content);
  }

  test(
      'exports only supplied invoices and retains numeric totals and numbering',
      () {
    final input = [selected];
    final sheet = worksheet(input);
    expect(RegExp(r'<row r=').allMatches(sheet), hasLength(2));
    expect(sheet, contains('selected-invoice'));
    expect(
        sheet,
        contains(
            '<c r="B2" t="inlineStr" s="0"><is><t xml:space="preserve">001-26</t>'));
    expect(sheet, contains('<c r="G2" s="2"><v>100</v></c>'));
    expect(sheet, contains('<c r="H2" s="2"><v>21</v></c>'));
    expect(sheet, contains('<c r="I2" s="2"><v>121</v></c>'));
    expect(input, [selected]);
  });

  test('customer text is escaped, control characters removed, formulas inert',
      () {
    final sheet = worksheet([selected], client: '=1+1 & <Cliente>\u0001');
    expect(sheet, contains('=1+1 &amp; &lt;Cliente&gt;'));
    expect(sheet, isNot(contains('\u0001')));
    expect(sheet, isNot(contains('<f>')));
    expect(sheet, contains('<c r="C2" t="inlineStr"'));
  });

  test('missing totals remain blank instead of becoming zero', () {
    final sheet = worksheet([
      const Invoice(
          id: 'draft',
          invoiceNumber: 'legacy-9',
          groupId: 'group',
          clientId: 'customer',
          status: 'draft'),
    ]);
    expect(sheet, contains('Borrador'));
    expect(sheet, isNot(contains('legacy-9')));
    expect(sheet, isNot(contains('r="I2"')));
  });

  test('empty selection produces header only', () {
    final sheet = worksheet([]);
    expect(RegExp(r'<row r=').allMatches(sheet), hasLength(1));
    expect(sheet, contains('autoFilter ref="A1:J1"'));
  });
}
