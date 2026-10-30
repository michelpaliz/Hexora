import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/hexora_menu_content_transition.dart';

void main() {
  testWidgets('animates menu changes and preserves child state',
      (tester) async {
    var transitionKey = 'invoices';
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return HexoraMenuContentTransition(
              transitionKey: transitionKey,
              child: const _StatefulProbe(),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    rebuild(() => transitionKey = 'expenses');
    await tester.pump();

    final transition = find.byType(HexoraMenuContentTransition);
    final fadeFinder = find.descendant(
      of: transition,
      matching: find.byType(FadeTransition),
    );
    final fade = tester.widget<FadeTransition>(fadeFinder);
    final slide = tester.widget<SlideTransition>(
      find.descendant(
        of: transition,
        matching: find.byType(SlideTransition),
      ),
    );
    expect(fade.opacity.value, lessThan(1));
    expect(slide.transformHitTests, isFalse);
    expect(find.text('1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
  });

  testWidgets('skips visual motion when animations are disabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: HexoraMenuContentTransition(
            transitionKey: 'budgets',
            child: Text('Presupuestos'),
          ),
        ),
      ),
    );

    expect(find.text('Presupuestos'), findsOneWidget);
    final transition = find.byType(HexoraMenuContentTransition);
    expect(
      find.descendant(of: transition, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: transition, matching: find.byType(SlideTransition)),
      findsNothing,
    );
  });
}

class _StatefulProbe extends StatefulWidget {
  const _StatefulProbe();

  @override
  State<_StatefulProbe> createState() => _StatefulProbeState();
}

class _StatefulProbeState extends State<_StatefulProbe> {
  var count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => count++),
      child: Text('$count'),
    );
  }
}
