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
    expect(find.byTooltip('OCR / Revisar documento'), findsNWidgets(2));
    expect(find.byTooltip('Editar gasto'), findsNWidgets(2));
    expect(find.byTooltip('Eliminar gasto'), findsNWidgets(2));

    final actionCenters = [
      'Vista previa',
      'OCR / Revisar documento',
      'Editar gasto',
      'Eliminar gasto',
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

    await tester.tap(find.byTooltip('Eliminar gasto').first);
    await tester.pumpAndSettle();
    expect(find.text('Proveedor con un nombre extraordinariamente largo'),
        findsWidgets);
    expect(find.text('2026000723'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Proveedor').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Papelería');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Papelería Central'), findsOneWidget);
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
    expect(find.byTooltip('OCR / Revisar documento'), findsOneWidget);
    expect(find.byTooltip('Editar gasto'), findsOneWidget);
    expect(find.byTooltip('Eliminar gasto'), findsOneWidget);
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
    final disabledDelete = find.descendant(
      of: find.byTooltip('Eliminar gasto'),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(disabledDelete).onPressed, isNull);

    await pumpTab(canDelete: true);
    await tester.tap(find.byTooltip('Eliminar gasto'));
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
