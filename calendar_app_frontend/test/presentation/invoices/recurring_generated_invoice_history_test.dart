import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_generated_tab.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/delivery_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('generated invoice history is compact in $brightness',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(420, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      const invoice = Invoice(
        id: 'invoice-1',
        invoiceNumber: '382-26',
        groupId: 'group-1',
        clientId: 'client-1',
        status: 'issued',
        deliveryStatus: 'sent',
        deliveryChannel: 'email',
        isLinked: true,
        linkedEntriesCount: 2,
        currency: 'EUR',
        subtotal: 1279.36,
        taxTotal: 268.67,
        total: 1548.03,
      );
      var downloads = 0;

      await tester.pumpWidget(MaterialApp(
        theme:
            AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecurringDetailGeneratedTab(
            loading: false,
            error: null,
            invoices: const [invoice],
            onReload: () {},
            hasRequested: true,
            count: 1,
            onOpenInvoice: (_) {},
            onDownloadPdf: (_) => downloads++,
            onLoadInvoiceDetails: (_) async => invoice,
            onLoadInvoicePreviewBytes: (_) async => Uint8List(0),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('generated-invoice-row-invoice-1'));
      expect(row, findsOneWidget);
      expect(tester.getSize(row).height, inInclusiveRange(60, 68));
      expect(find.byType(HexoraStatusBadge), findsOneWidget);
      expect(find.text('Emitida'), findsOneWidget);
      expect(find.byType(DeliveryStatusBadge), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Tooltip &&
              (widget.message ?? '').contains('Enviada') &&
              (widget.message ?? '').contains('Email')),
          findsOneWidget);
      expect(find.byTooltip('Vinculada a 2 movimientos bancarios'),
          findsOneWidget);
      expect(find.textContaining('1.548,03'), findsOneWidget);
      expect(find.textContaining('Subtotal:'), findsNothing);
      expect(find.text('Mostrar PDF'), findsNothing);

      final menuFinder =
          find.byKey(const ValueKey('generated-invoice-menu-invoice-1'));
      final menu = tester.widget<PopupMenuButton<String>>(menuFinder);
      final items = menu.itemBuilder(tester.element(menuFinder));
      expect(items.whereType<PopupMenuItem<String>>().map((item) => item.value),
          containsAll(<String>['preview', 'download', 'details']));
      menu.onSelected?.call('download');
      expect(downloads, 1);
      await tester.tap(find.descendant(
        of: menuFinder,
        matching: find.byType(IconButton),
      ));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((widget) => widget is PopupMenuItem<String>),
          findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }
}
