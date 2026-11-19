import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hexora/models/invoice/invoice.dart';

/// Exports the exact displayed selection; no server-side filter reinterpretation.
Uint8List buildFilteredInvoicesExcel({
  required List<Invoice> invoices,
  Map<String, String> clientNames = const {},
  String defaultCurrency = 'EUR',
  bool spanish = true,
}) {
  const ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  const rel =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  String escape(String text) => const HtmlEscape().convert(
        text.replaceAll(
            RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\uFFFE\uFFFF]'), ''),
      );
  final rows = <List<Object?>>[
    spanish
        ? [
            'ID',
            'Factura',
            'Cliente',
            'Fecha',
            'Estado',
            'Moneda',
            'Base',
            'IVA',
            'Total',
            'Vinculada'
          ]
        : [
            'ID',
            'Invoice',
            'Customer',
            'Date',
            'Status',
            'Currency',
            'Subtotal',
            'Tax',
            'Total',
            'Linked'
          ],
    for (final invoice in invoices)
      [
        invoice.id,
        invoice.displayNumber(draftLabel: spanish ? 'Borrador' : 'Draft'),
        invoice.billingName?.trim().isNotEmpty == true
            ? invoice.billingName!
            : clientNames[invoice.clientId] ?? invoice.clientName ?? '',
        (invoice.issueDate ?? invoice.registeredAt)
                ?.toIso8601String()
                .split('T')
                .first ??
            '',
        invoice.status ?? '',
        invoice.currency ?? defaultCurrency,
        invoice.subtotal,
        invoice.taxTotal,
        invoice.total,
        invoice.isLinkedResolved ? (spanish ? 'Sí' : 'Yes') : 'No',
      ],
  ];
  final sheet = StringBuffer('<worksheet xmlns="$ns">'
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
      '<cols><col min="1" max="1" width="28" customWidth="1"/>'
      '<col min="2" max="2" width="18" customWidth="1"/>'
      '<col min="3" max="3" width="40" customWidth="1"/>'
      '<col min="4" max="10" width="16" customWidth="1"/></cols><sheetData>');
  for (var row = 0; row < rows.length; row++) {
    sheet.write('<row r="${row + 1}">');
    for (var col = 0; col < rows[row].length; col++) {
      final address = '${String.fromCharCode(65 + col)}${row + 1}';
      final value = rows[row][col];
      if (value == null) continue;
      if (value is num) {
        if (value.isFinite) {
          sheet.write('<c r="$address" s="2"><v>$value</v></c>');
        }
      } else {
        // Explicit strings keep invoice numbers intact and never become formulas.
        sheet.write('<c r="$address" t="inlineStr" s="${row == 0 ? 1 : 0}">'
            '<is><t xml:space="preserve">${escape(value.toString())}</t></is></c>');
      }
    }
    sheet.write('</row>');
  }
  sheet.write('</sheetData><autoFilter ref="A1:J${rows.length}"/></worksheet>');
  final files = <String, String>{
    '[Content_Types].xml':
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="xml" ContentType="application/xml"/>'
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
            '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>',
    '_rels/.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="$rel/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml': '<workbook xmlns="$ns" xmlns:r="$rel"><sheets>'
        '<sheet name="${spanish ? 'Facturas' : 'Invoices'}" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="$rel/worksheet" Target="worksheets/sheet1.xml"/>'
            '<Relationship Id="rId2" Type="$rel/styles" Target="styles.xml"/></Relationships>',
    'xl/styles.xml': '<styleSheet xmlns="$ns">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
        '<xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
    'xl/worksheets/sheet1.xml': sheet.toString(),
  };
  final archive = Archive();
  for (final entry in files.entries) {
    final bytes = utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>${entry.value}');
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
