import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/utils/with_loading_dialog.dart';

void main() {
  for (final dismissFirst in [false, true]) {
    testWidgets(
        dismissFirst
            ? 'task completion does not pop the page after dialog dismissal'
            : 'task completion closes the dialog even when back is blocked',
        (tester) async {
      final task = Completer<bool>();
      Future<bool?>? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: Builder(builder: (pageContext) {
                    return TextButton(
                      onPressed: () {
                        result = withLoadingDialog<bool>(
                          pageContext,
                          () => task.future,
                          barrierDismissible: dismissFirst,
                        );
                      },
                      child: const Text('Start task'),
                    );
                  }),
                ),
              )),
              child: const Text('Open page'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start task'));
      // The progress indicator intentionally animates while the task is pending.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      if (dismissFirst) {
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      }
      task.complete(true);
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Start task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
