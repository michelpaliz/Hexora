import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/views/presupuestos_view.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/theme/themes/app_theme.dart';

class _Api implements PresupuestosApi {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listByGroup) {
      return Future<List<Map<String, dynamic>>>.value([
        {
          '_id': 'budget-1',
          'status': 'issued',
          'deliveryStatus': 'sent',
          'deliveryChannel': 'email',
          'presupuestoNumber': '031-26',
          'clientName': 'Las Alondras Playa',
          'issueDate': '2026-10-28',
          'subtotal': 100,
          // Legacy list payloads can contain a stale zero even when lines
          // carry taxable VAT data.
          'taxTotal': 0,
          'total': 121,
          'lines': [
            {
              'description': 'Mantenimiento mensual de jardín',
              'quantity': 1,
              'unitPrice': 100,
              'taxRate': 21,
            },
          ],
        },
      ]);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  testWidgets('presupuestos table shows the description column',
      (tester) async {
    String? editedBudgetId;
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromBrightness(Brightness.light),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GroupInvoicesBudgetsView(
          groupId: 'group-1',
          clients: const [],
          api: _Api(),
          onEditDraftBudget: (id) async => editedBudgetId = id,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Descripción'), findsOneWidget);
    expect(find.text('Mantenimiento mensual de jardín'), findsOneWidget);
    expect(find.text('100,00 €'), findsOneWidget);
    expect(find.text('21,00 €'), findsOneWidget);
    expect(find.text('Envío'), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.byTooltip('Vista previa'), findsOneWidget);
    expect(find.byTooltip('Editar presupuesto emitido'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar presupuesto emitido'));
    await tester.pump();
    expect(editedBudgetId, 'budget-1');

    await tester.tap(find.byTooltip('Vista previa'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('document-preview-drawer')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
