import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';

void main() {
  testWidgets('toolbar uses full width and scrolls to trailing actions',
      (tester) async {
    for (final width in [360.0, 1100.0]) {
      var pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 300,
            child: FolderPanel(
              actions: [
                const SizedBox(width: 480, child: Text('Calendar views')),
                const SizedBox(width: 400, child: Text('Period controls')),
                TextButton(
                  onPressed: () => pressed = true,
                  child: const Text('Member filter'),
                ),
              ],
              child: const Text('Calendar grid'),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      final scroll = find.byType(SingleChildScrollView);
      expect(tester.getSize(scroll).width,
          greaterThan(width * .9 > 720 ? 720 : width * .9));
      await tester.drag(scroll, const Offset(-1200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Member filter'));
      expect(pressed, isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('FolderPanel omits title-only toolbar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 300,
            child: FolderPanel(
              title: 'Screen folder title',
              child: Text('Screen content'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Screen folder title'), findsNothing);
    expect(find.text('Screen content'), findsOneWidget);
  });

  testWidgets('screen section can hide folder tab and retain actions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderSectionCard(
            label: 'Todos los movimientos',
            showTitle: false,
            actions: const [Icon(Icons.refresh)],
            child: const Text('Transactions'),
          ),
        ),
      ),
    );

    expect(find.text('Todos los movimientos'), findsNothing);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
