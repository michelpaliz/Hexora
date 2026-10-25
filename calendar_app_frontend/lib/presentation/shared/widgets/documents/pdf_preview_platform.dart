import 'package:flutter/foundation.dart';

/// Mobile browsers cannot reliably display PDFs in embedded browser frames.
bool useRenderedPdfPreview({
  required TargetPlatform platform,
  required double viewportWidth,
  bool touchMac = false,
}) =>
    platform == TargetPlatform.android ||
    platform == TargetPlatform.iOS ||
    touchMac ||
    viewportWidth < 720;
