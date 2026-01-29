import 'dart:typed_data';

import 'file_download_launcher_stub.dart'
    if (dart.library.html) 'file_download_launcher_web.dart';

Future<void> launchFileDownload(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) =>
    launchFileDownloadImpl(
      bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
