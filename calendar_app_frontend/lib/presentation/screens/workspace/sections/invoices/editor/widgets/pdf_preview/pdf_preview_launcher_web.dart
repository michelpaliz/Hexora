import 'dart:async';
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
  // Keep the object URL alive while the new tab starts loading. Revoking it
  // synchronously can leave the preview blank in Chromium-based browsers.
  Timer(const Duration(minutes: 1), () => html.URL.revokeObjectURL(url));
}
