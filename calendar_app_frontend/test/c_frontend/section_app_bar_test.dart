import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/section_app_bar.dart';

void main() {
  testWidgets('back returns to the previous route', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(
                      appBar: SectionAppBar(title: 'Mapa'),
                      body: Text('Map content'),
                    ),
                  )),
                  child: const Text('Open map'),
                ),
              )),
    ));
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open map'), findsOneWidget);
    expect(find.text('Map content'), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long title, actions and tabs fit a small phone in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var backPressed = false;
      var refreshPressed = false;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: SectionAppBar(
              title: 'Servicios y clientes con un nombre muy largo',
              onBack: () => backPressed = true,
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => refreshPressed = true,
                  icon: const Icon(Icons.refresh),
                )
              ],
              bottom: const TabBar(tabs: [Tab(text: 'A'), Tab(text: 'B')]),
            ),
            body: const TabBarView(children: [Text('First'), Text('Second')]),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Refresh'));
      await tester.tap(find.byType(BackButton));
      expect(refreshPressed, isTrue);
      expect(backPressed, isTrue);
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
