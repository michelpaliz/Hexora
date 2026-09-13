import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_payment_editor.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('mobile payment editing is explicit at $scale text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Scaffold(
            body: SingleChildScrollView(
                child: InvoicePaymentEditor(
          invoice: const Invoice(
              id: 'invoice',
              invoiceNumber: '324-26',
              groupId: 'g',
              clientId: 'c',
              total: 100,
              paymentStatus: 'unpaid'),
          onSave: (payload) async {
            saved = payload;
          },
        ))),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Guardar cambios'), findsNothing);
      expect(find.text('Pendiente'), findsOneWidget);
      await tester.tap(find.byTooltip('Editar pago'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pago parcial').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '150');
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(
          find.text(
              'El pago parcial debe ser menor que el total de la factura.'),
          findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '25');
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(saved?['paymentStatus'], 'partial');
      expect(saved?['paidAmount'], 25);
      expect(find.text('Guardar cambios'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Editar pago'));
      await tester.tap(find.byTooltip('Editar pago'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '40');
      final l = AppLocalizations.of(
          tester.element(find.byType(InvoicePaymentEditor)))!;
      await tester.ensureVisible(find.text(l.cancel));
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(find.text('Pago parcial · 25 EUR'), findsOneWidget);
      expect(saved?['paidAmount'], 25);
      expect(tester.takeException(), isNull);
    });
  }
}
