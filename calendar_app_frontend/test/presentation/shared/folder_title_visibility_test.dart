import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';

void main() {
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
