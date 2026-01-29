import 'dart:typed_data';

Future<void> launchFileDownloadImpl(
  Uint8List _bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  throw UnsupportedError('File download is not supported on this platform yet.');
}
