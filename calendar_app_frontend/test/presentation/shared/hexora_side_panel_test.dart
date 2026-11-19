import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/panels/hexora_side_panel.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required Size size,
    required ValueChanged<String?> onResult,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await HexoraSidePanelHost.show<String>(
                    context,
                    preferredWidth: 520,
                    builder: (panelContext) => HexoraSidePanel(
                      key: const ValueKey('side-panel'),
                      header: const HexoraSidePanelHeader(
                        title: 'Vincular factura',
                      ),
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(panelContext).pop('closed'),
                        child: const Text('CLOSE_PANEL'),
                      ),
                    ),
                  );
                  onResult(result);
                },
                child: const Text('OPEN_PANEL'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('side panel host overlays the page on desktop', (tester) async {
    String? result;
    await pumpHost(
      tester,
      size: const Size(1200, 800),
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('OPEN_PANEL'));
    await tester.pumpAndSettle();

    expect(find.text('Vincular factura'), findsOneWidget);
    final panelSize = tester.getSize(find.byKey(const ValueKey('side-panel')));
    expect(panelSize.width, lessThan(1200));
    expect(panelSize.height, lessThan(800));

    await tester.tap(find.text('CLOSE_PANEL'));
    await tester.pumpAndSettle();

    expect(find.text('Vincular factura'), findsNothing);
    expect(result, 'closed');
  });

  testWidgets('side panel host covers the viewport on mobile', (tester) async {
    String? result;
    await pumpHost(
      tester,
      size: const Size(600, 900),
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('OPEN_PANEL'));
    await tester.pumpAndSettle();

    expect(find.text('Vincular factura'), findsOneWidget);
    final panelSize = tester.getSize(find.byKey(const ValueKey('side-panel')));
    expect(panelSize.width, 600);
    expect(panelSize.height, 900);

    await tester.tap(find.text('CLOSE_PANEL'));
    await tester.pumpAndSettle();

    expect(find.text('Vincular factura'), findsNothing);
    expect(result, 'closed');
  });

  testWidgets('header shows back only when there is a previous step',
      (tester) async {
    var back = 0;
    var close = 0;
    Widget header(VoidCallback? onBack) => MaterialApp(
          theme: AppTheme.forPlatform(
            Brightness.dark,
            platform: TargetPlatform.windows,
          ),
          home: Scaffold(
            body: HexoraSidePanelHeader(
              title: 'Vincular movimiento',
              onBack: onBack,
              backTooltip: 'Volver',
              onClose: () => close++,
              closeTooltip: 'Cerrar',
            ),
          ),
        );

    await tester.pumpWidget(header(null));
    expect(find.byTooltip('Volver'), findsNothing);
    expect(find.byTooltip('Cerrar'), findsOneWidget);

    await tester.pumpWidget(header(() => back++));
    await tester.tap(find.byTooltip('Volver'));
    await tester.tap(find.byTooltip('Cerrar'));
    expect(back, 1);
    expect(close, 1);
  });

  testWidgets('inline side panel closes on Escape', (tester) async {
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: Scaffold(
          body: HexoraSidePanel(
            embedded: true,
            title: 'Vincular factura',
            onClose: () => closed++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(closed, 1);
  });

  Future<void> pumpLayout(
    WidgetTester tester, {
    required Size size,
    required ScrollController scroll,
    Widget? panel,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: Scaffold(
          body: HexoraSidePanelLayout(
            panel: panel,
            child: ListView.builder(
              key: const ValueKey('main-list'),
              controller: scroll,
              itemCount: 200,
              itemBuilder: (_, i) =>
                  SizedBox(height: 40, child: Text('ROW $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('docked layout keeps the page beside the panel', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpLayout(tester, size: const Size(1400, 800), scroll: scroll);
    scroll.jumpTo(2000);
    await tester.pump();

    const panel = HexoraSidePanel(
      key: ValueKey('docked-panel'),
      embedded: true,
      title: 'Vincular',
      child: SizedBox.expand(),
    );
    await pumpLayout(
      tester,
      size: const Size(1400, 800),
      scroll: scroll,
      panel: panel,
    );

    final panelRect =
        tester.getRect(find.byKey(const ValueKey('docked-panel')));
    final listRect = tester.getRect(find.byKey(const ValueKey('main-list')));
    expect(panelRect.width, inInclusiveRange(420, 520));
    expect(panelRect.right, 1400);
    expect(listRect.right, lessThanOrEqualTo(panelRect.left));
    expect(scroll.offset, 2000);

    await pumpLayout(tester, size: const Size(1400, 800), scroll: scroll);
    expect(find.text('Vincular'), findsNothing);
    expect(scroll.offset, 2000);
  });

  testWidgets('narrow layout covers the page with the panel', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpLayout(
      tester,
      size: const Size(600, 900),
      scroll: scroll,
      panel: const HexoraSidePanel(
        key: ValueKey('narrow-panel'),
        embedded: true,
        title: 'Vincular',
        child: SizedBox.expand(),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('narrow-panel'))).width,
      600,
    );
  });
}
