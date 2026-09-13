import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload/form_sections/tabs/recent_uploads_tab.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('expenses at 320px, $brightness, text scale $scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? deleted;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.fromBrightness(brightness)
              .copyWith(platform: TargetPlatform.android),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ExpenseRecentUploadsTab(
                groupId: '',
                recentUploads: [
                  {
                    'id': 'one',
                    'vendor': 'Proveedor con un nombre muy largo de servicios',
                    'invoice': 'FACTURA-2026-000000123456789',
                    'total': '1234567.89',
                    'currency': 'EUR',
                    'date': '2026-06-01'
                  },
                  {
                    'id': 'two',
                    'vendor': 'Papelería',
                    'total': '42.00',
                    'currency': 'EUR',
                    'date': '2026-09-01'
                  },
                ],
                selectedExpense: null,
                onSelectExpense: (_) {},
                onDeleteExpense: (id) async {
                  deleted = id;
                },
                previewLoading: false,
                previewError: null,
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('2 gastos'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Papelería');
        await tester.pumpAndSettle();
        expect(find.text('1 gasto'), findsOneWidget);
        expect(find.text('Proveedor con un nombre muy largo de servicios'),
            findsNothing);
        await tester.tap(find.byTooltip('Acciones del gasto'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(ExpenseRecentUploadsTab));
        await tester.tap(find.text(AppLocalizations.of(context)!.remove));
        await tester.pumpAndSettle();
        expect(deleted, 'two');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
