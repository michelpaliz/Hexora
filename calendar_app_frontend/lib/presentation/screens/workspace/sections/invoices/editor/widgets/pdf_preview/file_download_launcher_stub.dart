import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'file_download_outcome.dart';

Future<FileDownloadOutcome> launchFileDownloadImpl(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  final mobile = Platform.isAndroid || Platform.isIOS;
  final path = await FilePicker.platform
      .saveFile(fileName: fileName, bytes: mobile ? bytes : null);
  if (path == null) return FileDownloadOutcome.cancelled;
  if (!mobile) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
  return FileDownloadOutcome.saved;
}
