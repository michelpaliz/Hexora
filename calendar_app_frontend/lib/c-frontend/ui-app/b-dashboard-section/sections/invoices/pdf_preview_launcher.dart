import 'dart:typed_data';

import 'pdf_preview_launcher_stub.dart'
    if (dart.library.html) 'pdf_preview_launcher_web.dart';

Future<void> launchPdfPreview(Uint8List bytes,
        {String fileName = 'invoice-preview.pdf'}) =>
    launchPdfPreviewImpl(bytes, fileName: fileName);
