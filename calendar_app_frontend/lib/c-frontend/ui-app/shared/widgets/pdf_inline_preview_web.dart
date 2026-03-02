// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

class PdfInlinePreview extends StatefulWidget {
  const PdfInlinePreview({
    super.key,
    required this.bytes,
    this.height = 420,
  });

  final Uint8List bytes;
  final double height;

  @override
  State<PdfInlinePreview> createState() => _PdfInlinePreviewState();
}

class _PdfInlinePreviewState extends State<PdfInlinePreview> {
  late final String _viewType;
  late html.IFrameElement _element;
  String? _url;

  @override
  void initState() {
    super.initState();
    _viewType = 'pdf-inline-${DateTime.now().microsecondsSinceEpoch}';
    _element = html.IFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    _setUrl(widget.bytes);

    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _element,
    );
  }

  @override
  void didUpdateWidget(covariant PdfInlinePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes) {
      _setUrl(widget.bytes);
    }
  }

  void _setUrl(Uint8List bytes) {
    if (_url != null) {
      html.Url.revokeObjectUrl(_url!);
    }
    final blob = html.Blob([bytes], 'application/pdf');
    _url = html.Url.createObjectUrlFromBlob(blob);
    _element.src = _url!;
  }

  @override
  void dispose() {
    if (_url != null) {
      html.Url.revokeObjectUrl(_url!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
