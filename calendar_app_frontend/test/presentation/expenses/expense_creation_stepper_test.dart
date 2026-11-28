import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_wizard_navigation.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/form_sections/expense_creation_stepper.dart';

const steps = [
  DocumentWizardStep(label: 'Documento', icon: Icons.description_outlined),
  DocumentWizardStep(label: 'Datos', icon: Icons.edit_note, sections: [
    DocumentWizardSection(id: 'general', label: 'General', icon: Icons.edit),
  ]),
  DocumentWizardStep(label: 'Revisión', icon: Icons.fact_check),
  DocumentWizardStep(label: 'Guardado', icon: Icons.save),
];

void main() {
  testWidgets(
      'collapse preserves form and current step, unavailable steps cannot open',
      (tester) async {
    var collapsed = false;
    var current = 1;
    var valid = false;
    late StateSetter rebuild;
    final controller = TextEditingController(text: 'Existing expense');
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return Row(children: [
          ExpenseCreationStepper(
            steps: steps,
            currentStep: current,
            collapsed: collapsed,
            forcedCollapsed: false,
            canSelect: (step) => step < 2 || (step == 2 && valid),
            isComplete: (step) => step == 0 || (step == 1 && valid),
            onSelected: (step) => setState(() => current = step),
            onToggle: () => setState(() => collapsed = !collapsed),
            selectedSection: 'general',
            onSectionSelected: (_) {},
          ),
          Expanded(child: TextField(controller: controller)),
        ]);
      })),
    ));
    expect(find.text('Nuevo gasto'), findsOneWidget);
    expect(find.text('Paso 2 de 4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('expense-stepper-step-2')));
    expect(current, 1);
    await tester.tap(find.byKey(const Key('expense-stepper-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('expense-stepper'))).width, 56);
    expect(find.byTooltip('Expandir pasos'), findsOneWidget);
    expect(controller.text, 'Existing expense');
    rebuild(() => valid = true);
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-stepper-step-2')));
    await tester.pump();
    expect(current, 2);
    await tester.tap(find.byKey(const Key('expense-stepper-toggle')));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('expense-stepper'))).width, 216);
    expect(find.text('Paso 3 de 4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('expense-stepper-step-0')));
    await tester.pump();
    expect(current, 0);
    rebuild(() => valid = false);
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-stepper-step-2')));
    expect(current, 0);
    expect(controller.text, 'Existing expense');
    expect(tester.takeException(), isNull);
  });

  testWidgets('constrained rail and mobile menu respect locks', (tester) async {
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Row(children: [
      ExpenseCreationStepper(
        steps: steps,
        currentStep: 0,
        collapsed: false,
        forcedCollapsed: true,
        canSelect: (step) => step == 0,
        isComplete: (_) => false,
        onSelected: (step) => selected = step,
        onToggle: () {},
        selectedSection: 'general',
        onSectionSelected: (_) {},
      ),
      Expanded(
          child: DocumentWizardMobileSelector(
        steps: steps,
        currentStep: 0,
        selectedSectionId: null,
        canSelectStep: (step) => step == 0,
        onStepSelected: (step) => selected = step,
        onSectionSelected: (_) {},
      )),
    ]))));
    expect(tester.getSize(find.byKey(const Key('expense-stepper'))).width, 56);
    expect(
        tester
            .widget<IconButton>(find.byKey(const Key('expense-stepper-toggle')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const Key('document-wizard-mobile-selector')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PopupMenuItem<String>>(
                find.widgetWithText(PopupMenuItem<String>, 'Revisión'))
            .enabled,
        isFalse);
    expect(selected, 0);
    expect(tester.takeException(), isNull);
  });
}
