import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/presentation/utils/logo/logo_widget.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('bundled branding loads without distortion in $brightness',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(
          body: Column(children: [
            HexoraBrandIcon(),
            HexoraWordmark(),
          ]),
        ),
      ));
      final context = tester.element(find.byType(Scaffold));
      await tester.runAsync(() async {
        await precacheImage(const AssetImage(HexoraBrandAssets.icon), context);
        await precacheImage(
            const AssetImage(HexoraBrandAssets.wordmark), context);
      });
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images[0].image, const AssetImage(HexoraBrandAssets.icon));
      expect(images[0].fit, BoxFit.cover);
      expect(tester.getSize(find.byType(Image).first), const Size(40, 40));
      expect(images[1].image, const AssetImage(HexoraBrandAssets.wordmark));
      expect(images[1].fit, BoxFit.contain);
      expect(tester.getSize(find.byType(Image).last), const Size(220, 110));
      expect(find.byType(ClipOval), findsNothing);
      expect(find.bySemanticsLabel('Hexora'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('branding can exclude redundant identity labels', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(children: [
          HexoraBrandIcon(excludeFromSemantics: true),
          HexoraWordmark(excludeFromSemantics: true),
          Text('Hexora'),
        ]),
      ),
    ));
    expect(find.bySemanticsLabel('Hexora'), findsOneWidget);
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      expect(image.excludeFromSemantics, isTrue);
      expect(image.semanticLabel, isNull);
    }
    semantics.dispose();
  });

  testWidgets('legacy LogoWidget uses the official icon at its existing sizes',
      (tester) async {
    for (final entry in {
      LogoSize.small: 80.0,
      LogoSize.medium: 150.0,
      LogoSize.large: 200.0,
    }.entries) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LogoWidget.buildLogoAvatar(size: entry.key)),
      ));
      expect(tester.widget<HexoraBrandIcon>(find.byType(HexoraBrandIcon)).size,
          entry.value);
      expect(find.byType(ClipOval), findsNothing);
    }
  });
}
