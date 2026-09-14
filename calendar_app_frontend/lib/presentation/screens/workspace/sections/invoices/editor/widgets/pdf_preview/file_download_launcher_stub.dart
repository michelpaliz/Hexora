import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<void> launchFileDownloadImpl(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  final mobile = Platform.isAndroid || Platform.isIOS;
  final path = await FilePicker.platform
      .saveFile(fileName: fileName, bytes: mobile ? bytes : null);
  if (!mobile && path != null) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
}
