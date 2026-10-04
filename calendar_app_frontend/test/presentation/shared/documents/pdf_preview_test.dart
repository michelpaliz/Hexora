import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart';
import 'package:pdfrx/pdfrx.dart';

// The widget runner does not bundle native PDFium. Exercise document loading
// failures here; actual PDF rendering is checked on the Android emulator.
class FailingPdfEngine implements PdfrxEntryFunctions {
  final loaded = <Uint8List>[];
  @override
  Future<void> init() async {}

  @override
  Future<PdfDocument> openData(
    Uint8List data, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    String? sourceName,
    bool allowDataOwnershipTransfer = false,
    bool useProgressiveLoading = false,
    void Function()? onDispose,
  }) async {
    loaded.add(data);
    throw const FormatException('Invalid PDF');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Uint8List document() => Uint8List.fromList(ascii.encode('%PDF-invalid'));

void main() {
  final engine = FailingPdfEngine();
  setUp(() {
    PdfrxEntryFunctions.instance = engine;
    engine.loaded.clear();
  });

  Widget app(Widget body) => MaterialApp(
        navigatorKey: SessionExpiryHandler.navigatorKey,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: body),
      );

  testWidgets(
      'native PDF reports load failures and retries replacement documents',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = document();
    await tester.pumpWidget(app(PdfInlinePreview(bytes: bytes)));
    await tester.pumpAndSettle();
    expect(find.byType(PdfViewer), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(engine.loaded, contains(bytes));
    expect(
        find.text(
            AppLocalizations.of(tester.element(find.byType(PdfInlinePreview)))!
                .invoicePdfPreviewFailedSnack),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    final oldKey = tester.widget<PdfViewer>(find.byType(PdfViewer)).key;
    await tester.pumpWidget(app(PdfInlinePreview(bytes: document())));
    expect(tester.widget<PdfViewer>(find.byType(PdfViewer)).key, isNot(oldKey));
    await tester.pumpAndSettle();
    expect(engine.loaded.length, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('native preview opens full screen and closes back to the form',
      (tester) async {
    await tester.pumpWidget(app(const Text('Form')));
    final closed = launchPdfPreview(document(), fileName: 'recibo.pdf');
    await tester.pumpAndSettle();
    expect(find.text('recibo.pdf'), findsOneWidget);
    expect(find.byType(PdfViewer), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await closed;
    expect(find.text('Form'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
