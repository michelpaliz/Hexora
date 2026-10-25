import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_preview_platform.dart';

void main() {
  test('mobile browsers render PDFs even in landscape or on tablets', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      for (final width in [320.0, 390.0, 844.0, 1366.0]) {
        expect(useRenderedPdfPreview(platform: platform, viewportWidth: width), true);
      }
    }
    expect(useRenderedPdfPreview(platform: TargetPlatform.macOS, viewportWidth: 1024, touchMac: true), true);
  });
  test('desktop retains its browser viewer except at phone-sized widths', () {
    for (final platform in [TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macOS]) {
      expect(useRenderedPdfPreview(platform: platform, viewportWidth: 1280), false);
      expect(useRenderedPdfPreview(platform: platform, viewportWidth: 390), true);
    }
  });
}
