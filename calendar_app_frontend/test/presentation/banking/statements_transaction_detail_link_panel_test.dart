import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/statements_transaction_detail_link_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/bank_transaction_link_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  final unlinkedEntry = <String, dynamic>{
    '_id': 'entry-1',
    'date': '2026-08-01',
    'description': 'TRANSFERENCIA CLIENTE ACME',
    'amount': '1210.00',
    'balance': '5400.00',
    'clientName': 'Acme SL',
  };

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Map<String, dynamic> entry,
    StatementsTransactionPanelTab initialTab =
        StatementsTransactionPanelTab.details,
    BankTransactionLinkMode initialLinkMode = BankTransactionLinkMode.suggestions,
    VoidCallback? onClose,
    Future<void> Function()? onMarkNotApplicable,
    String? notApplicableReason,
    Size size = const Size(520, 820),
  }) async {
    final controller = StatementsController(useAggregated: false)
      ..entries = [entry]
      ..allEntries = [entry];
    addTearDown(controller.dispose);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

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
          body: StatementsTransactionDetailLinkPanel(
            controller: controller,
            entry: entry,
            initialTab: initialTab,
            initialLinkMode: initialLinkMode,
            onClose: onClose ?? () {},
            onMarkNotApplicable: onMarkNotApplicable,
            notApplicableReason: notApplicableReason,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  int activeTabIndex(WidgetTester tester) =>
      tester.widget<TabBarView>(find.byType(TabBarView)).controller!.index;

  testWidgets('opening from the list defaults to the Detalles tab',
      (tester) async {
    await pumpPanel(tester, entry: unlinkedEntry);

    expect(activeTabIndex(tester), 0);
    expect(find.text('Detalles'), findsOneWidget);
    expect(find.text('Vincular'), findsOneWidget);
    // The shared header carries amount/date/status once; neither tab repeats
    // a transaction summary card.
    expect(find.textContaining('1.210,00'), findsOneWidget);
    expect(find.text('Sin vincular'), findsOneWidget);
  });

  testWidgets('a Vincular action defaults to the Vincular tab', (tester) async {
    await pumpPanel(
      tester,
      entry: unlinkedEntry,
      initialTab: StatementsTransactionPanelTab.link,
    );

    expect(activeTabIndex(tester), 1);
  });

  testWidgets('tapping the other tab switches the active index',
      (tester) async {
    // Bounded pumps, not pumpAndSettle: the Vincular tab's suggestions
    // request is a real (unresolved, in-test) network call, so its loading
    // spinner animates indefinitely and would make pumpAndSettle hang.
    await pumpPanel(tester, entry: unlinkedEntry);
    expect(activeTabIndex(tester), 0);

    await tester.tap(find.text('Vincular'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(activeTabIndex(tester), 1);

    await tester.tap(find.text('Detalles'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(activeTabIndex(tester), 0);
  });

  testWidgets('linked transactions report their status once in the header',
      (tester) async {
    await pumpPanel(
      tester,
      entry: {
        ...unlinkedEntry,
        'invoiceIds': ['invoice-1'],
      },
    );

    expect(find.text('Vinculado'), findsOneWidget);
    expect(find.text('Sin vincular'), findsNothing);
  });

  testWidgets('close button and Escape both invoke onClose', (tester) async {
    var closed = 0;
    await pumpPanel(tester, entry: unlinkedEntry, onClose: () => closed++);

    await tester.tap(find.byTooltip('Cerrar'));
    expect(closed, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(closed, greaterThanOrEqualTo(2));
  });
}
