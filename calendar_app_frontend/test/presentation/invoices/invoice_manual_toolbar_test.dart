import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/invoice/invoice_block.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/form/invoice_content_section.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      locale: const Locale('es'),
      theme: ThemeData(
        brightness: brightness,
        extensions: const [_typography],
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Form(child: child)),
    );

InvoiceContentDiscountConfig _discount() => InvoiceContentDiscountConfig(
      readOnly: false,
      usePercent: false,
      amountCtrl: TextEditingController(),
      percentCtrl: TextEditingController(),
      effectiveDiscountAmount: 0,
      total: 100,
      onModePercentChanged: (_) {},
      onAmountChanged: (_) {},
      onPercentChanged: (_) {},
    );

Future<List<InvoiceBlockDraft>> _pump(
  WidgetTester tester, {
  required Size size,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final blocks = <InvoiceBlockDraft>[];
  await tester.pumpWidget(_app(
    StatefulBuilder(
      builder: (context, setState) => InvoiceContentSection(
        blocks: blocks,
        total: 100,
        onChanged: () => setState(() {}),
        discountConfig: _discount(),
        showSaveDraftButton: false,
      ),
    ),
    brightness: brightness,
  ));
  // The capabilities request never resolves offline; the toolbar uses the
  // fallback block types meanwhile (with a small spinner), so don't settle.
  await _settle(tester);
  return blocks;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('manual actions live in one horizontal toolbar', (tester) async {
    final blocks = await _pump(tester, size: const Size(1280, 900));

    expect(find.byKey(const ValueKey('invoice-manual-toolbar')), findsOne);
    // Old vertical palette section headers are gone.
    expect(find.text('Facturable'), findsNothing);
    expect(find.text('Contenido'), findsNothing);

    // Primary actions are direct buttons.
    for (final id in [
      InvoiceBlockType.item,
      InvoiceBlockType.checklist,
      InvoiceBlockType.worker,
      InvoiceBlockType.note,
    ]) {
      expect(find.byKey(ValueKey('invoice-toolbar-add-$id')), findsOne,
          reason: id);
    }
    // Structural types are only reachable through the dropdown.
    expect(find.byKey(const ValueKey('invoice-toolbar-add-section')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('invoice-toolbar-add-item')));
    await _settle(tester);
    expect(blocks.map((b) => b.type), [InvoiceBlockType.item]);

    await tester.tap(find.byKey(const ValueKey('invoice-toolbar-add-note')));
    await _settle(tester);
    expect(blocks.last.type, InvoiceBlockType.note);

    await tester.tap(find.byKey(const ValueKey('invoice-toolbar-structure')));
    await _settle(tester);
    for (final id in [
      InvoiceBlockType.section,
      InvoiceBlockType.subsection,
      InvoiceBlockType.divider,
    ]) {
      expect(find.byKey(ValueKey('invoice-toolbar-add-$id')), findsOne,
          reason: id);
    }
    await tester
        .tap(find.byKey(const ValueKey('invoice-toolbar-add-divider')));
    await _settle(tester);
    expect(blocks.last.type, InvoiceBlockType.divider);
    expect(blocks, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Descuento toggles the inline discount strip', (tester) async {
    await _pump(tester, size: const Size(1280, 900));

    expect(find.byKey(const ValueKey('invoice-discount-strip')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('invoice-toolbar-discount')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('invoice-discount-strip')), findsOne);
    expect(find.byKey(const ValueKey('invoice-discount-field')), findsOne);

    await tester.tap(find.byKey(const ValueKey('invoice-toolbar-discount')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('invoice-discount-strip')), findsNothing);
  });

  for (final width in [360.0, 768.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('toolbar fits at width $width ($brightness)',
          (tester) async {
        await _pump(tester, size: Size(width, 800), brightness: brightness);
        expect(find.byKey(const ValueKey('invoice-manual-toolbar')), findsOne);
        expect(tester.takeException(), isNull);
        // Narrow screens scroll the toolbar sideways; the last action is
        // still reachable.
        final structure =
            find.byKey(const ValueKey('invoice-toolbar-structure'));
        await tester.ensureVisible(structure);
        await _settle(tester);
        await tester.tap(structure);
        await _settle(tester);
        expect(find.byKey(const ValueKey('invoice-toolbar-add-section')),
            findsOne);
      });
    }
  }
}
