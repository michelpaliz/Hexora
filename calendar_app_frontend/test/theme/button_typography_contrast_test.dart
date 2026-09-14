import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final platform in [TargetPlatform.android, TargetPlatform.linux]) {
      testWidgets('button labels inherit variant colors: $brightness $platform',
          (tester) async {
        final theme = AppTheme.forPlatform(brightness, platform: platform);
        final typography = theme.extension<AppTypography>()!;
        expect(typography.buttonText.color, isNull);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
              body: Column(children: [
            for (final enabled in [true, false])
              for (final kind in ['text', 'outlined', 'filled', 'elevated'])
                Builder(builder: (context) {
                  Widget button(bool styled) {
                    final child = Text('$kind-$enabled-$styled',
                        style: styled
                            ? AppTypography.of(context).buttonText
                            : null);
                    final VoidCallback? onPressed = enabled ? () {} : null;
                    return switch (kind) {
                      'text' => TextButton(onPressed: onPressed, child: child),
                      'outlined' =>
                        OutlinedButton(onPressed: onPressed, child: child),
                      'filled' =>
                        FilledButton(onPressed: onPressed, child: child),
                      _ => ElevatedButton(onPressed: onPressed, child: child),
                    };
                  }

                  return Row(children: [button(false), button(true)]);
                }),
          ])),
        ));
        await tester.pumpAndSettle();
        Color colorFor(String label) {
          final richText = find.descendant(
              of: find.text(label), matching: find.byType(RichText));
          return tester
              .renderObject<RenderParagraph>(richText)
              .text
              .style!
              .color!;
        }

        for (final enabled in [true, false]) {
          for (final kind in ['text', 'outlined', 'filled', 'elevated']) {
            expect(colorFor('$kind-$enabled-true'),
                colorFor('$kind-$enabled-false'),
                reason:
                    '$kind must preserve the button foreground, including disabled state');
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
