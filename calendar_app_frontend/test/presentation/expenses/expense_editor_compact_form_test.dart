import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/form_fields.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/expense_document_totals_fields.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_lines.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_models.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/provider_picker.dart';

void main() {
  testWidgets(
      'expense form localizes dates and does not duplicate a saved supplier',
      (tester) async {
    final vendor = TextEditingController(text: 'COMERCIAL MARINA COLOR, S.L.');
    final issueDate = TextEditingController(text: '2028-04-28T00:00:00.000Z');
    final dueDate = TextEditingController(text: '2028-05-28');
    final vendorTaxId = TextEditingController(text: 'B03470663');
    final invoice = TextEditingController(text: '26005579');
    final currency = TextEditingController(text: 'EUR');
    final notes = TextEditingController();
    final clientId = TextEditingController();
    addTearDown(() {
      vendor.dispose();
      issueDate.dispose();
      dueDate.dispose();
      vendorTaxId.dispose();
      invoice.dispose();
      currency.dispose();
      notes.dispose();
      clientId.dispose();
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 620,
          height: 800,
          child: ExpenseFormFields(
            groupName: 'Grupo',
            groupId: 'group-1',
            providerPicker: const Text('COMERCIAL MARINA COLOR, S.L.'),
            vendorController: vendor,
            issueDateController: issueDate,
            vendorTaxIdController: vendorTaxId,
            invoiceNumberController: invoice,
            dueDateController: dueDate,
            currencyController: currency,
            notesController: notes,
            clientIdController: clientId,
            settlementFields: const SizedBox.shrink(),
            discountFields: const SizedBox.shrink(),
            withholdingFields: const SizedBox.shrink(),
            totalsFields: const SizedBox.shrink(),
            linesEditor: const SizedBox.shrink(),
            vatBreakdown: const SizedBox.shrink(),
            hasLines: false,
            submitting: false,
            manualProvider: false,
            onPickDate: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('COMERCIAL MARINA COLOR, S.L.'), findsOneWidget);
    expect(find.text('28 abr 2028'), findsOneWidget);
    expect(find.text('28 may 2028'), findsOneWidget);
    expect(find.text('2028-04-28T00:00:00.000Z'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('amount source only shows manual totals in document mode',
      (tester) async {
    final base = TextEditingController(text: '100');
    final tax = TextEditingController(text: '21');
    final total = TextEditingController(text: '121');
    addTearDown(() {
      base.dispose();
      tax.dispose();
      total.dispose();
    });
    var useDocumentTotals = false;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.dark,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 700,
            child: ExpenseDocumentTotalsFields(
              baseController: base,
              taxController: tax,
              totalController: total,
              enabled: true,
              useSummaryTotals: useDocumentTotals,
              lockToLines: true,
              onSummaryModeChanged: (value) =>
                  setState(() => useDocumentTotals = value),
              onBaseChanged: (_) {},
              onTaxChanged: (_) {},
              onTotalChanged: (_) {},
              financialSummary: const Text('Resumen financiero'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Origen de los importes'), findsOneWidget);
    expect(find.text('Desde líneas'), findsOneWidget);
    expect(find.text('Desde documento'), findsOneWidget);
    expect(find.text('Resumen financiero'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Puedes revisar'), findsNothing);

    await tester.tap(find.text('Desde documento'));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(3));
    await tester.enterText(find.byType(TextField).first, '200');

    await tester.tap(find.text('Desde líneas'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(base.text, '200');

    await tester.tap(find.text('Desde documento'));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(3));
    expect(base.text, '200');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact expense lines expand one row and preserve draft state',
      (tester) async {
    final first = ExpenseLineDraft.fromMap({
      'description': 'Riego',
      'quantity': 2,
      'baseUnitPrice': 25,
      'taxRate': 21,
    });
    final second = ExpenseLineDraft.fromMap({
      'description': 'Poda',
      'quantity': 1,
      'baseUnitPrice': 40,
      'taxRate': 21,
    });
    addTearDown(() {
      first.dispose();
      second.dispose();
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 700,
          child: ExpenseLinesEditor(
            lines: [first, second],
            compactWorkspace: true,
            onAddLine: () {},
            onRemoveLine: (_) {},
            onLinesChanged: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(6));
    await tester.tap(find.text('Poda'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(6));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.controller == second.descriptionController,
      ),
      findsOneWidget,
    );
    expect(first.descriptionController.text, 'Riego');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'supplier picker searches accent-insensitively and enters manual mode',
      (tester) async {
    String? selectedProviderId;
    var manualMode = false;
    final providers = <Map<String, dynamic>>[
      {
        'id': 'provider-1',
        'name': 'García Verde, S.L.',
        'taxId': 'B12345678',
        'reference': 'JARDIN-01',
      },
      {
        'id': 'provider-2',
        'name': 'Marina Color',
        'taxId': 'A87654321',
      },
    ];

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 480,
            height: 320,
            child: ExpenseProviderPicker(
              providers: providers,
              selectedProviderId: selectedProviderId,
              providersError: null,
              loading: false,
              manualMode: manualMode,
              onSelectProvider: (id) => setState(() => selectedProviderId = id),
              onManualMode: () => setState(() {
                selectedProviderId = null;
                manualMode = true;
              }),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Proveedor existente'), findsNothing);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'garcia');
    await tester.pumpAndSettle();
    final garcia = find.textContaining('García Verde', findRichText: true);
    expect(garcia, findsOneWidget);

    await tester.tap(garcia);
    await tester.pumpAndSettle();
    expect(selectedProviderId, 'provider-1');

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Introducir proveedor manualmente'));
    await tester.pumpAndSettle();
    expect(manualMode, isTrue);
    expect(find.text('Proveedor manual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
