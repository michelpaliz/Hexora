import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';

void main() {
  testWidgets('content state survives toolbar visibility changes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _PanelHarness()));

    await tester.tap(find.text('Count 0'));
    await tester.pump();
    expect(find.text('Count 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-toolbar')));
    await tester.pump();

    expect(find.text('Count 1'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });
}

class _PanelHarness extends StatefulWidget {
  const _PanelHarness();

  @override
  State<_PanelHarness> createState() => _PanelHarnessState();
}

class _PanelHarnessState extends State<_PanelHarness> {
  bool _showToolbar = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            TextButton(
              key: const ValueKey('toggle-toolbar'),
              onPressed: () => setState(() => _showToolbar = !_showToolbar),
              child: const Text('Toggle toolbar'),
            ),
            Expanded(
              child: FolderPanel(
                actions: _showToolbar ? const [Icon(Icons.refresh)] : null,
                child: const _Counter(),
              ),
            ),
          ],
        ),
      );
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => _count++),
        child: Text('Count $_count'),
      );
}
