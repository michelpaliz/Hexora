import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/define_themes/dark_theme.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/define_themes/light_theme.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/define_themes/mobile_theme.dart';

// Test actual foreground/background pairs, including selected controls and errors.
double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    testWidgets(
        '$brightness chip labels remain readable when selection changes',
        (tester) async {
      final theme =
          AppTheme.forPlatform(brightness, platform: TargetPlatform.android);
      var selected = false;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            return ChoiceChip(
              label: const Text('Ubicaciones'),
              selected: selected,
              onSelected: (value) => setState(() => selected = value),
            );
          }),
        ),
      ));

      void expectReadable(Color background) {
        final context = tester.element(find.text('Ubicaciones'));
        final foreground = DefaultTextStyle.of(context).style.color!;
        expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
      }

      expectReadable(theme.chipTheme.backgroundColor!);
      await tester.tap(find.text('Ubicaciones'));
      await tester.pumpAndSettle();
      expectReadable(theme.chipTheme.selectedColor!);
      await tester.tap(find.text('Ubicaciones'));
      await tester.pumpAndSettle();
      expectReadable(theme.chipTheme.backgroundColor!);
    });

    testWidgets(
        '$brightness leaves every web and native desktop theme unchanged',
        (tester) async {
      final original = brightness == Brightness.dark ? darkTheme : lightTheme;
      for (final platform in TargetPlatform.values) {
        expect(
            AppTheme.forPlatform(brightness, platform: platform, isWeb: true),
            same(original));
        if (platform != TargetPlatform.android &&
            platform != TargetPlatform.iOS) {
          expect(AppTheme.forPlatform(brightness, platform: platform),
              same(original));
        }
      }
    });

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets(
          '$platform $brightness provides readable mobile surfaces and actions',
          (tester) async {
        final theme = AppTheme.forPlatform(brightness, platform: platform);
        final cs = theme.colorScheme;
        expect(theme.extension<MobileStatusColors>(), isNotNull);
        expect(theme.scaffoldBackgroundColor, cs.surface);
        expect(theme.canvasColor, cs.surface);
        expect(theme.appBarTheme.backgroundColor, cs.surface);
        expect(theme.cardTheme.color, cs.surfaceContainerLow);
        expect(theme.cardTheme.color, isNot(cs.surface));
        final pairs = [
          (cs.onSurface, cs.surface),
          (cs.onSurface, cs.surfaceContainerLow),
          (cs.onSurfaceVariant, cs.surfaceContainerHigh),
          (cs.onPrimary, cs.primary),
          (cs.onPrimaryContainer, cs.primaryContainer),
          (cs.onSecondaryContainer, cs.secondaryContainer),
          (cs.onError, cs.error),
          (cs.error, cs.errorContainer),
          (cs.onTertiaryContainer, cs.tertiaryContainer),
        ];
        for (final pair in pairs) {
          expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5),
              reason: '$pair');
        }
        expect(theme.filledButtonTheme.style!.minimumSize!.resolve({}),
            const Size(48, 48));
        expect(theme.iconButtonTheme.style!.minimumSize!.resolve({}),
            const Size(48, 48));
      });
    }
  }
}
