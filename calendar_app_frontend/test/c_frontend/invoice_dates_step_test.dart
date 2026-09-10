import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_dates_step.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

Widget _testApp({
  required Locale locale,
  required ValueNotifier<DateTime?> invoiceDate,
  required ValueNotifier<DateTime?> dueDate,
  required VoidCallback onContinue,
}) {
  return MaterialApp(
    locale: locale,
    theme: ThemeData(extensions: const [_typography]),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: InvoiceDatesStep(
          currencyController: TextEditingController(text: 'EUR'),
          invoiceDate: invoiceDate,
          dueDate: dueDate,
          notesController: TextEditingController(),
          onPickInvoiceDate: () {},
          onPickDueDate: () {},
          onCurrencyChanged: (_) {},
          onNotesChanged: (_) {},
          onBack: () {},
          onContinue: onContinue,
        ),
      ),
    ),
  );
}

FilledButton _continueButton(WidgetTester tester, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget is FilledButton),
  );
  return tester.widget<FilledButton>(finder);
}

void main() {
  testWidgets('requires an invoice date before continuing', (tester) async {
    final invoiceDate = ValueNotifier<DateTime?>(null);
    final dueDate = ValueNotifier<DateTime?>(null);
    addTearDown(invoiceDate.dispose);
    addTearDown(dueDate.dispose);
    var continueCalls = 0;

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('en'),
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        onContinue: () => continueCalls++,
      ),
    );

    expect(find.text('Select an invoice date to continue.'), findsOneWidget);
    var button = _continueButton(tester, 'Continue to line items');
    expect(button.onPressed, isNull);

    invoiceDate.value = DateTime(2026, 8, 30);
    await tester.pump();

    expect(find.text('Aug 30, 2026'), findsOneWidget);
    button = _continueButton(tester, 'Continue to line items');
    expect(button.onPressed, isNotNull);
    await tester.ensureVisible(find.text('Continue to line items'));
    await tester.tap(find.text('Continue to line items'));
    expect(continueCalls, 1);
  });

  testWidgets('uses the active locale and rejects an earlier due date',
      (tester) async {
    final invoiceDate = ValueNotifier<DateTime?>(DateTime(2026, 8, 30));
    final dueDate = ValueNotifier<DateTime?>(DateTime(2026, 8, 20));
    addTearDown(invoiceDate.dispose);
    addTearDown(dueDate.dispose);

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('es'),
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        onContinue: () {},
      ),
    );

    expect(
      find.text(DateFormat.yMMMd('es').format(invoiceDate.value!)),
      findsOneWidget,
    );
    expect(
      find.text(
        'La fecha de vencimiento no puede ser anterior a la fecha de factura.',
      ),
      findsOneWidget,
    );
    final button = _continueButton(tester, 'Continuar a líneas');
    expect(button.onPressed, isNull);
  });
}
