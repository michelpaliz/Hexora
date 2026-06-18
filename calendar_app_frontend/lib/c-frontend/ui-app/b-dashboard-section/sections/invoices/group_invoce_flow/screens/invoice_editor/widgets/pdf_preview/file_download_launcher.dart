import 'dart:typed_data';

import 'package:hexora/c-frontend/ui-app/shared/downloads/session_download_registry.dart';

import 'file_download_launcher_stub.dart'
    if (dart.library.html) 'file_download_launcher_web.dart';

Future<void> launchFileDownload(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  final registry = SessionDownloadRegistry.instance;
  final downloadId = registry.startDownload(
    fileName: fileName,
    mimeType: mimeType,
    sizeBytes: bytes.lengthInBytes,
  );

  try {
    await launchFileDownloadImpl(
      bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    registry.markHandedToBrowser(downloadId);
  } catch (error) {
    registry.markError(downloadId, error);
    rethrow;
  }
}
