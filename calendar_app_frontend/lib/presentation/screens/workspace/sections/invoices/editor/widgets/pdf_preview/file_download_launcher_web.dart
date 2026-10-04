import 'dart:js_interop';
import 'package:web/web.dart' as html;
import 'dart:typed_data';

Future<void> launchFileDownloadImpl(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  final blob =
      html.Blob([bytes.toJS].toJS, html.BlobPropertyBag(type: mimeType));
  final url = html.URL.createObjectURL(blob);
  final anchor = html.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  html.URL.revokeObjectURL(url);
}
