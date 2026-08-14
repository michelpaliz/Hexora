import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/shared/invoice_link/invoice_link_dialog_state.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/shared/invoice_link/invoice_link_dialog_steps.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/shared/invoice_link/invoice_link_confirmation.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  test('invoice selection stays open and keeps multiple invoice ids', () {
    final state = InvoiceLinkDialogState(
      currentInvoiceId: null,
      currentInvoiceIds: const [],
      currentClientId: 'client-1',
      currentProviderId: null,
      expenseOnly: false,
    );
    addTearDown(state.dispose);

    var stateChanges = 0;
    void onStateChanged() => stateChanges++;

    state.toggleInvoiceSelection('invoice-1', onStateChanged);
    state.toggleInvoiceSelection('invoice-2', onStateChanged);

    expect(state.selectedInvoiceIds, {'invoice-1', 'invoice-2'});
    expect(state.visibleStep, 1);
    expect(stateChanges, 2);

    state.toggleInvoiceSelection('invoice-1', onStateChanged);

    expect(state.selectedInvoiceIds, {'invoice-2'});
    expect(state.visibleStep, 1);
  });

  testWidgets('invoice selector keeps multiple rows selected without overflow',
      (tester) async {
    final state = InvoiceLinkDialogState(
      currentInvoiceId: null,
      currentInvoiceIds: const [],
      currentClientId: 'client-1',
      currentProviderId: null,
      expenseOnly: false,
    );
    addTearDown(state.dispose);
    state.invoiceCacheByClient['client-1'] = const [
      Invoice(
        id: 'invoice-1',
        invoiceNumber: '261-26',
        groupId: 'group-1',
        clientId: 'client-1',
        status: 'issued',
        total: 1572.21,
        currency: 'EUR',
      ),
      Invoice(
        id: 'invoice-2',
        invoiceNumber: '260-26',
        groupId: 'group-1',
        clientId: 'client-1',
        status: 'issued',
        total: 2359.60,
        currency: 'EUR',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 820,
              height: 520,
              child: StatefulBuilder(
                builder: (context, setState) {
                  final steps = InvoiceLinkDialogSteps(
                    state: state,
                    context: context,
                    cs: Theme.of(context).colorScheme,
                    l: AppLocalizations.of(context)!,
                    stacked: false,
                    groupId: 'group-1',
                    pickerClients: [
                      GroupClient(id: 'client-1', name: 'Sueño de Denia IV'),
                    ],
                    invoicesApi: InvoicesApi(),
                    expensesApi: ExpensesApi(),
                  );
                  return steps.buildInvoiceSelector(
                    () => setState(() {}),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();

    expect(state.selectedInvoiceIds, {'invoice-1', 'invoice-2'});
    expect(find.text('2 seleccionado(s) · 3.931,81 EUR'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 360,
            child: Builder(
              builder: (context) => SingleChildScrollView(
                child: InvoiceLinkConfirmation.build(
                  context,
                  state,
                  false,
                  AppLocalizations.of(context)!,
                  Theme.of(context).colorScheme,
                  () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total facturas'), findsOneWidget);
    expect(find.textContaining('3.931,81'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
