import 'dart:js_interop';
import 'package:web/web.dart' as html;
import 'dart:typed_data';

Future<void> launchPdfPreviewImpl(Uint8List bytes,
    {String fileName = 'invoice-preview.pdf'}) async {
  final blob = html.Blob(
      [bytes.toJS].toJS, html.BlobPropertyBag(type: 'application/pdf'));
  final url = html.URL.createObjectURL(blob);
  // Open in new tab so user can view/download
  html.window.open(url, '_blank');
  html.URL.revokeObjectURL(url);
}
