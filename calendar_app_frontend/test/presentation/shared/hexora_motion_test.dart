import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/presentation/shared/widgets/motion/hexora_step_transition.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

void main() {
  testWidgets('step transitions respect reduced motion', (tester) async {
    Widget app({required bool reduceMotion, required int step}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: HexoraStepTransition(
              step: step,
              child: Text('Step $step'),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(app(reduceMotion: true, step: 0));
    await tester.pumpWidget(app(reduceMotion: true, step: 1));

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
    expect(find.text('Step 1'), findsOneWidget);
    expect(HexoraMotion.chart, const Duration(milliseconds: 750));
    expect(
        HexoraMotion.expansionStyle(tester.element(find.text('Step 1')))
            .duration,
        Duration.zero);
    expect(
        HexoraMotion.sheetStyle(tester.element(find.text('Step 1'))).duration,
        Duration.zero);
  });

  testWidgets('shared dialog opens and dismisses without replacing page state',
      (tester) async {
    var pageValue = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                Text('Value $pageValue'),
                TextButton(
                  onPressed: () => setState(() => pageValue++),
                  child: const Text('Increment'),
                ),
                TextButton(
                  onPressed: () => showHexoraDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Motion dialog'),
                    ),
                  ),
                  child: const Text('Open dialog'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Increment'));
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Motion dialog'), findsOneWidget);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('Motion dialog'), findsNothing);
    expect(find.text('Value 1'), findsOneWidget);
  });
}
