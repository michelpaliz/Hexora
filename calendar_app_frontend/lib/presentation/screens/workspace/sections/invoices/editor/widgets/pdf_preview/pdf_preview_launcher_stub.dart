import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';

Future<void> launchPdfPreviewImpl(Uint8List bytes,
    {String fileName = 'invoice-preview.pdf'}) async {
  final navigator = SessionExpiryHandler.navigatorKey.currentState;
  if (navigator == null) {
    throw StateError('The document preview requires an active navigator.');
  }
  await navigator.push<void>(MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(title: Text(fileName, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: PdfInlinePreview(bytes: bytes, height: double.infinity),
      ),
    ),
  ));
}
