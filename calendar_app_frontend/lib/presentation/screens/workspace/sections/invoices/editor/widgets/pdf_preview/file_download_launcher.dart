import 'dart:typed_data';

import 'package:hexora/presentation/shared/downloads/session_download_registry.dart';
import 'file_download_outcome.dart';

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
    final outcome = await launchFileDownloadImpl(
      bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    switch (outcome) {
      case FileDownloadOutcome.saved:
        registry.markSaved(downloadId);
      case FileDownloadOutcome.handedOff:
        registry.markHandedToBrowser(downloadId);
      case FileDownloadOutcome.cancelled:
        registry.markCancelled(downloadId);
    }
  } catch (error) {
    registry.markError(downloadId, error);
    rethrow;
  }
}
