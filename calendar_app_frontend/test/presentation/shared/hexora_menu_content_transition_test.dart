import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/hexora_menu_content_transition.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

void main() {
  test('exposes distinct module, submenu, and internal tab profiles', () {
    const child = SizedBox.shrink();
    const module = HexoraMenuContentTransition.module(
      transitionKey: 'module',
      child: child,
    );
    const submenu = HexoraMenuContentTransition.submenu(
      transitionKey: 'submenu',
      child: child,
    );
    const tab = HexoraMenuContentTransition.tab(
      transitionKey: 'tab',
      child: child,
    );

    expect(module.duration, HexoraMotion.moduleNavigation);
    expect(module.translateX, 10);
    expect(submenu.duration, HexoraMotion.submenuNavigation);
    expect(submenu.translateX, 0);
    expect(tab.duration, HexoraMotion.tabNavigation);
    expect(tab.translateX, 0);
  });

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

  testWidgets('module profile uses requested timing and preserves module state',
      (tester) async {
    var transitionKey = 'invoices';
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return HexoraMenuContentTransition.module(
              transitionKey: transitionKey,
              child: _LabeledProbe(label: transitionKey),
            );
          },
        ),
      ),
    );

    expect(
      tester
          .widget<HexoraMenuContentTransition>(
            find.byType(HexoraMenuContentTransition),
          )
          .duration,
      HexoraMotion.moduleNavigation,
    );
    await tester.tap(find.text('invoices:0'));
    await tester.pump();
    expect(find.text('invoices:1'), findsOneWidget);

    rebuild(() => transitionKey = 'expenses');
    await tester.pump();
    final transition = find.byType(HexoraMenuContentTransition);
    final fade = tester.widget<FadeTransition>(
      find.descendant(of: transition, matching: find.byType(FadeTransition)),
    );
    expect(fade.opacity.value, closeTo(0.86, 0.001));

    await tester.pump(const Duration(milliseconds: 90));
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.text('expenses:0'), findsOneWidget);

    rebuild(() => transitionKey = 'invoices');
    await tester.pumpAndSettle();
    expect(find.text('invoices:1'), findsOneWidget);
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

class _LabeledProbe extends StatefulWidget {
  const _LabeledProbe({required this.label});

  final String label;

  @override
  State<_LabeledProbe> createState() => _LabeledProbeState();
}

class _LabeledProbeState extends State<_LabeledProbe> {
  var count = 0;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => count++),
        child: Text('${widget.label}:$count'),
      );
}
