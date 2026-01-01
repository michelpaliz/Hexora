// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> launchPdfPreviewImpl(Uint8List bytes,
    {String fileName = 'invoice-preview.pdf'}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // Open in new tab so user can view/download
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);
}
