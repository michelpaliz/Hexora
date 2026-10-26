import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';

void main() {
  testWidgets('dismissible success snack still expires with accessibility on',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSuccessSnack(
                context,
                'Tus cambios se guardaron.',
                title: 'Borrador actualizado',
                actionLabel: 'Cerrar',
              ),
              child: const Text('Guardar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.action, isNull);
    expect(find.text('Cerrar'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Borrador actualizado'), findsNothing);
  });

  testWidgets('inline dismiss button closes the success snack immediately',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSuccessSnack(
                context,
                'Guardado.',
                actionLabel: 'Cerrar',
              ),
              child: const Text('Mostrar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Guardado.'), findsNothing);
  });
}
