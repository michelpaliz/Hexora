import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class InvoiceEditorPdf {
  static Uint8List validatePdf(http.Response r) {
    final bytes = r.bodyBytes;
    final ct = (r.headers['content-type'] ?? '').toLowerCase();
    final looksPdf =
        bytes.length > 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';
    if (bytes.isNotEmpty && (ct.contains('pdf') || looksPdf)) return bytes;

    // Some backends return a JSON object of byte values. Try to reconstruct.
    try {
      final parsed =
          jsonDecode(utf8.decode(bytes, allowMalformed: true)) as Map?;
      if (parsed != null && parsed.isNotEmpty) {
        final orderedKeys = parsed.keys
            .map((k) => int.tryParse(k.toString()) ?? -1)
            .where((k) => k >= 0)
            .toList()
          ..sort();

        final buffer = List<int>.generate(
          orderedKeys.length,
          (i) => parsed[orderedKeys[i].toString()] as int? ?? 0,
        );

        final rebuilt = Uint8List.fromList(buffer);
        final looksRebuiltPdf = rebuilt.length > 4 &&
            String.fromCharCodes(rebuilt.take(4)) == '%PDF';
        if (looksRebuiltPdf) return rebuilt;
      }
    } catch (_) {
      // fall through to error
    }

    final sample = utf8.decode(bytes.take(200).toList(), allowMalformed: true);
    throw Exception(sample.isNotEmpty
        ? 'Preview failed: $sample'
        : 'Preview failed: empty response (${r.statusCode})');
  }
}
