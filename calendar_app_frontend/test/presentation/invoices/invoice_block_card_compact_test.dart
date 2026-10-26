import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/invoice/invoice_block.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/blocks_table/block_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/services/invoicing/models/manual_editor_capabilities.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('invoice item card stays compact and formats Spanish totals',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final draft = InvoiceBlockDraft(
      type: InvoiceBlockType.item,
      conceptTitle: 'B30',
      conceptItems: const ['Mantenimiento'],
      description: 'Mantenimiento mensual',
      qty: '1',
      unit: 'ud',
      unitPrice: '1490,40',
      discountRate: '0',
      taxRate: '21',
      isBillable: true,
    );
    addTearDown(draft.dispose);
    var selections = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: BlockCard(
                index: 0,
                total: 1,
                block: draft,
                selected: true,
                availableBlockTypes:
                    ManualEditorCapabilities.fallback().blockTypes,
                onSelect: () => selections++,
                onDelete: () {},
                onMoveUp: () {},
                onMoveDown: () {},
                onChanged: () {},
                onAddChecklistItem: () {},
                onRemoveChecklistItem: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('invoice-line-card-0'));
    expect(tester.getSize(card).height, inInclusiveRange(44, 58));
    expect(find.textContaining('1 ud × 1.490,40 €'), findsOneWidget);
    expect(find.text('1.803,38 €'), findsOneWidget);

    await tester.tap(find.text('Mantenimiento'));
    await tester.pumpAndSettle();

    expect(tester.getSize(card).height, inInclusiveRange(120, 150));
    expect(find.text('Vivienda / unidad'), findsOneWidget);
    expect(find.text('Concepto de trabajo'), findsOneWidget);
    expect(find.text('Seleccionar fecha'), findsOneWidget);
    expect(find.text('Detalle'), findsOneWidget);
    expect(find.text('Descuento %'), findsOneWidget);

    EditableText fieldFor(TextEditingController controller) => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .singleWhere((field) => field.controller == controller);
    expect(fieldFor(draft.qtyCtrl).textAlign, TextAlign.right);
    expect(fieldFor(draft.unitPriceCtrl).textAlign, TextAlign.right);
    expect(fieldFor(draft.discountRateCtrl).textAlign, TextAlign.right);
    expect(fieldFor(draft.taxRateCtrl).textAlign, TextAlign.right);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is EditableText && widget.controller == draft.qtyCtrl,
      ),
    );
    await tester.pump();
    expect(selections, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('invoice item fields wrap without overflow on narrow layouts',
      (tester) async {
    tester.view.physicalSize = const Size(520, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final draft = InvoiceBlockDraft(
      type: InvoiceBlockType.item,
      conceptItems: const ['Servicio'],
      description: 'Detalle',
      qty: '2',
      unitPrice: '50',
      discountRate: '0',
      taxRate: '21',
    );
    addTearDown(draft.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.dark,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.topCenter,
              child: BlockCard(
                index: 0,
                total: 1,
                block: draft,
                selected: false,
                availableBlockTypes:
                    ManualEditorCapabilities.fallback().blockTypes,
                onSelect: () {},
                onDelete: () {},
                onMoveUp: () {},
                onMoveDown: () {},
                onChanged: () {},
                onAddChecklistItem: () {},
                onRemoveChecklistItem: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle'), findsWidgets);
    expect(find.text('IVA %'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
