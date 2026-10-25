@TestOn('browser')
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/widgets/presupuesto_pdf_preview_dialog.dart';
import 'package:pdfrx/pdfrx.dart';

Uint8List samplePdf() {
  const stream = 'BT /F1 24 Tf 40 240 Td (Hexora PDF preview) Tj ET';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
  ];
  var pdf = '%PDF-1.4\n';
  final offsets = <int>[0];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(pdf.length);
    pdf += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final xref = pdf.length;
  pdf += 'xref\n0 6\n0000000000 65535 f \n';
  for (final offset in offsets.skip(1)) {
    pdf += '${offset.toString().padLeft(10, '0')} 00000 n \n';
  }
  pdf += 'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF';
  return Uint8List.fromList(ascii.encode(pdf));
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform mobile browser renders a real PDF without an iframe', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var downloads = 0;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PresupuestoPdfPreviewDialog(bytes: samplePdf(), onDownload: () => downloads++),
      ));
      await tester.pump();
      expect(find.byType(HtmlElementView), findsNothing);
      final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
      await tester.runAsync(() async {
        await viewer.documentRef.resolveListenable().useDocument((document) async {
          expect(document, isNotNull);
          expect(document!.pages.length, 1);
          final image = await document.pages.first.render(width: 300, height: 300);
          expect(image, isNotNull);
          image?.dispose();
        });
      });
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Descargar'));
      expect(downloads, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('desktop web keeps the browser iframe', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PdfInlinePreview(bytes: samplePdf()))));
    expect(find.byType(HtmlElementView), findsOneWidget);
    expect(find.byType(PdfViewer), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
