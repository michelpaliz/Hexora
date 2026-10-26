import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/tabs/recent_uploads_tab.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('desktop expenses use compact table and persisted split selector',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromBrightness(Brightness.light),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExpenseRecentUploadsTab(
          groupId: '',
          recentUploads: const [
            {
              'id': 'one',
              'vendor': 'Proveedor con un nombre extraordinariamente largo',
              'invoice': '2026000723',
              'subtotal': '9.00',
              'tax': '0.00',
              'total': '9.00',
              'currency': 'EUR',
              'date': '2026-10-20',
              'file': 'ticket.pdf',
              'status': 'verified',
            },
            {
              'id': 'two',
              'vendor': 'Papelería Central',
              'invoice': 'P-44',
              'subtotal': '100.00',
              'tax': '21.00',
              'total': '121.00',
              'currency': 'EUR',
              'date': '2026-10-21',
              'file': 'invoice.pdf',
              'status': 'verified',
            },
          ],
          selectedExpense: null,
          onSelectExpense: (_) {},
          onDeleteExpense: (_) async {},
          previewLoading: false,
          previewError: null,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(HexoraFilterableHeaderCell), findsNWidgets(7));
    expect(find.byTooltip('Vista compacta'), findsOneWidget);
    expect(find.byTooltip('Vista extendida'), findsOneWidget);
    expect(find.byTooltip('Vista previa'), findsNWidgets(2));
    expect(find.byTooltip('Editar gasto'), findsNWidgets(2));
    expect(find.byTooltip('OCR / Revisar documento'), findsNothing);
    expect(find.byTooltip('Eliminar gasto'), findsNothing);
    expect(find.text('Resumen de gastos'), findsNothing);
    expect(find.text('Según filtros activos'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('expense-desktop-toolbar')))
          .height,
      44,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('expense-summary-strip')))
          .height,
      40,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('expense-table-header'))).height,
      36,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('expense-row-one'))).height,
      inInclusiveRange(44, 48),
    );
    expect(
      find.byTooltip('Proveedor con un nombre extraordinariamente largo'),
      findsOneWidget,
    );

    final actionCenters = [
      'Vista previa',
      'Editar gasto',
      'Más acciones',
    ]
        .map((tooltip) => tester.getCenter(find.byTooltip(tooltip).first))
        .toList();
    expect(
      actionCenters.map((center) => center.dy),
      everyElement(closeTo(actionCenters.first.dy, 0.5)),
      reason: 'Every expense action must share the same vertical center.',
    );
    for (var index = 1; index < actionCenters.length; index++) {
      expect(actionCenters[index].dx, greaterThan(actionCenters[index - 1].dx));
    }

    await tester.tap(find.text('Estado IVA').first);
    await tester.pumpAndSettle();
    final vatDialog = find.byType(Dialog);
    final verifiedFilter = find
        .descendant(
          of: vatDialog,
          matching: find.text('Verificado'),
        )
        .first;
    await tester.tap(verifiedFilter);
    await tester.pump();
    expect(find.byKey(const ValueKey('vat-filter-loading')), findsOneWidget);
    await tester.tap(verifiedFilter);
    await tester.pump();
    await tester.tapAt(const Offset(1300, 700));
    await tester.pump(const Duration(milliseconds: 200));

    final firstMoreMenu = find
        .ancestor(
          of: find.byTooltip('Más acciones').first,
          matching: find.byWidgetPredicate(
            (widget) => widget is PopupMenuButton<String>,
          ),
        )
        .first;
    await tester.tap(firstMoreMenu);
    await tester.pumpAndSettle();
    expect(find.text('OCR / Revisar documento'), findsOneWidget);
    expect(find.text('Eliminar gasto'), findsOneWidget);
    await tester.tap(find.text('Eliminar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Proveedor con un nombre extraordinariamente largo'),
        findsWidgets);
    expect(find.text('2026000723'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Proveedor').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Papelería');
    await tester.pump();
    expect(find.text('Papelería Central'), findsWidgets);
    await tester.tap(find.text('Papelería Central').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Proveedor con un nombre extraordinariamente largo'),
      findsNothing,
    );
    await tester.tapAt(const Offset(1300, 700));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Vista extendida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byTooltip('Vista previa'), findsNothing);
    expect(find.byTooltip('Editar gasto'), findsOneWidget);
    expect(find.byTooltip('OCR / Revisar documento'), findsNothing);
    expect(find.byTooltip('Eliminar gasto'), findsNothing);
    expect(find.byTooltip('Más acciones'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expense deletion respects permissions and reports rejection',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpTab({required bool canDelete}) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.fromBrightness(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExpenseRecentUploadsTab(
            groupId: '',
            recentUploads: const [
              {
                'id': 'protected',
                'vendor': 'Proveedor protegido',
                'invoice': 'FAC-9',
                'total': '90.00',
                'currency': 'EUR',
                'date': '2026-10-20',
                'file': 'protected.pdf',
              },
            ],
            selectedExpense: null,
            onSelectExpense: (_) {},
            onDeleteExpense: (_) async => throw StateError('protected'),
            canDeleteExpenses: canDelete,
            previewLoading: false,
            previewError: null,
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    await pumpTab(canDelete: false);
    Finder moreMenu() => find
        .ancestor(
          of: find.byTooltip('Más acciones'),
          matching: find.byWidgetPredicate(
            (widget) => widget is PopupMenuButton<String>,
          ),
        )
        .first;
    await tester.tap(moreMenu());
    await tester.pumpAndSettle();
    expect(find.text('Eliminar gasto'), findsNothing);
    await tester.tapAt(const Offset(1000, 600));
    await tester.pumpAndSettle();

    await pumpTab(canDelete: true);
    await tester.tap(moreMenu());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar gasto').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('registros contables o fiscales protegidos'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
