import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/mobile_section_tabs.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('invoice mobile layout $brightness at $scale text scale',
          (tester) async {
        tester.view.physicalSize = const Size(320, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TabController(length: 4, vsync: tester);
        addTearDown(controller.dispose);
        var opened = false;
        var edited = false;
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
            body: Column(children: [
              MobileSectionTabs(controller: controller, labels: const [
                'Facturas',
                'Recibos',
                'Clientes',
                'Presupuestos'
              ]),
              Expanded(
                  child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  InvoiceListItem(
                    mobile: true,
                    invoice: const Invoice(
                        id: 'one',
                        invoiceNumber: 'FACTURA-2026-000123456789',
                        groupId: 'group',
                        clientId: 'client',
                        total: 1234567.89,
                        status: 'draft'),
                    client: GroupClient(
                        id: 'client',
                        name: 'FERCAMAR GESTIÓN ALMERÍA S.L. con nombre largo',
                        isActive: true),
                    onTap: () => opened = true,
                    onEdit: () => edited = true,
                  ),
                ],
              )),
            ]),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Presupuestos'));
        await tester.pumpAndSettle();
        expect(controller.index, 3);
        controller.animateTo(1);
        await tester.pumpAndSettle();
        final button = tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Recibos'));
        final cs = Theme.of(tester.element(find.byType(MobileSectionTabs)))
            .colorScheme;
        expect(button.style!.backgroundColor!.resolve({}), cs.primary);
        await tester
            .tap(find.text('FERCAMAR GESTIÓN ALMERÍA S.L. con nombre largo'));
        expect(opened, isTrue);
        final context = tester.element(find.byType(InvoiceListItem));
        final edit = AppLocalizations.of(context)!.edit;
        await tester.tap(find.byTooltip(edit));
        await tester.pumpAndSettle();
        await tester.tap(find.text(edit));
        await tester.pumpAndSettle();
        expect(edited, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
