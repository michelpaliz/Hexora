import 'dart:js_interop';
import 'package:web/web.dart' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

class PdfInlinePreview extends StatefulWidget {
  const PdfInlinePreview({
    super.key,
    required this.bytes,
    this.height = 420,
    this.interactive = true,
  });

  final Uint8List bytes;
  final double height;
  final bool interactive;

  @override
  State<PdfInlinePreview> createState() => _PdfInlinePreviewState();
}

class _PdfInlinePreviewState extends State<PdfInlinePreview> {
  late final String _viewType;
  late html.HTMLIFrameElement _element;
  String? _url;

  @override
  void initState() {
    super.initState();
    _viewType = 'pdf-inline-${DateTime.now().microsecondsSinceEpoch}';
    _element = html.HTMLIFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = widget.interactive ? 'auto' : 'none';
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
    if (oldWidget.interactive != widget.interactive) {
      _element.style.pointerEvents = widget.interactive ? 'auto' : 'none';
    }
  }

  void _setUrl(Uint8List bytes) {
    if (_url != null) {
      html.URL.revokeObjectURL(_url!);
    }
    final blob = html.Blob(
        [bytes.toJS].toJS, html.BlobPropertyBag(type: 'application/pdf'));
    _url = html.URL.createObjectURL(blob);
    _element.src = '${_url!}#toolbar=1&navpanes=0&pagemode=none&view=FitH';
  }

  @override
  void dispose() {
    if (_url != null) {
      html.URL.revokeObjectURL(_url!);
    }
    _element.src = 'about:blank';
    _element.remove();
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
