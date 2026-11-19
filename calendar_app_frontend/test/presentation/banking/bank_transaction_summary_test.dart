import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/bank_transaction_summary.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Future<void> pumpSummary(
    WidgetTester tester,
    Map<String, dynamic> entry, {
    double width = 480,
    String? notApplicableReason,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
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
          body: SingleChildScrollView(
            child: BankTransactionSummary(
              entry: entry,
              notApplicableReason: notApplicableReason,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const unlinked = <String, dynamic>{
    '_id': 'entry-1',
    'date': '2026-08-01',
    'valueDate': '2026-08-03',
    'description': 'TRANSFERENCIA CLIENTE ACME',
    'amount': '1210.00',
    'balance': '5400.00',
    'clientName': 'Acme SL',
  };

  testWidgets('shows only amount, description, date and status by default',
      (tester) async {
    await pumpSummary(tester, unlinked);

    expect(tester.takeException(), isNull);
    expect(find.text('TRANSFERENCIA CLIENTE ACME'), findsOneWidget);
    expect(find.text('Sin vincular'), findsOneWidget);
    expect(find.text('Ver detalles'), findsOneWidget);
    expect(find.text('Saldo'), findsNothing);
    expect(find.text('Acme SL'), findsNothing);

    await tester.tap(find.text('Ver detalles'));
    await tester.pumpAndSettle();

    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('Acme SL'), findsOneWidget);
    expect(find.text('Fecha valor'), findsOneWidget);
    expect(find.text('Ocultar detalles'), findsOneWidget);
  });

  testWidgets('reports linked and not-applicable status', (tester) async {
    await pumpSummary(tester, {
      ...unlinked,
      'invoiceIds': ['invoice-1'],
      'invoiceNumbers': ['F-2026-0001'],
    });
    expect(find.text('Vinculado'), findsOneWidget);

    await pumpSummary(tester, unlinked, notApplicableReason: 'Comisión');
    expect(find.text('No procede'), findsOneWidget);
  });

  testWidgets('fits a 320px panel', (tester) async {
    await pumpSummary(
      tester,
      {
        ...unlinked,
        'description': 'TRANSFERENCIA ' * 12,
      },
      width: 320,
    );
    await tester.tap(find.text('Ver detalles'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
