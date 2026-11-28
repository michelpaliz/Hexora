@TestOn('browser')
library;

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/maps/widgets/azure_maps_view_web.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';

class _RecordingRegistry extends ui_web.PlatformViewRegistry {
  late html.IFrameElement frame;

  @override
  bool registerViewFactory(String viewType, Function viewFactory,
      {bool isVisible = true}) {
    frame = viewFactory(0) as html.IFrameElement;
    return super
        .registerViewFactory(viewType, viewFactory, isVisible: isVisible);
  }
}

void main() {
  testWidgets('map iframe suspends pointer events for dialogs and dropdowns',
      (tester) async {
    final registry = _RecordingRegistry();
    ui_web.debugOverridePlatformViewRegistry(registry);
    addTearDown(() => ui_web.debugOverridePlatformViewRegistry(null));
    final navigator = GlobalKey<NavigatorState>();
    late BuildContext pageContext;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: Scaffold(body: Builder(builder: (context) {
        pageContext = context;
        return Column(children: [
          DropdownButton<String>(
              value: 'all',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'missing', child: Text('Missing')),
              ],
              onChanged: (_) {}),
          Expanded(
              child: AzureMapsView(
            clientId: 'test',
            accessToken: 'test',
            pins: const [],
            selectedPinId: null,
            selection: null,
            userLocation: null,
            cameraTarget: null,
            onSelectionChanged: (_) {},
            onPinTapped: (_) {},
          )),
        ]);
      })),
    ));
    await tester.pumpAndSettle();
    final frame = registry.frame;
    expect(frame.style.pointerEvents, 'auto');
    final result = showHexoraDialog<bool>(
        context: pageContext,
        builder: (context) =>
            AlertDialog(title: const Text('Choose client'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Choose'))
            ]));
    await tester.pumpAndSettle();
    expect(frame.style.pointerEvents, 'none');
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(frame.style.pointerEvents, 'auto');
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(frame.style.pointerEvents, 'none');
    await tester.tap(find.text('Missing').last);
    await tester.pumpAndSettle();
    expect(frame.style.pointerEvents, 'auto');
    expect(tester.takeException(), isNull);
  });
}
