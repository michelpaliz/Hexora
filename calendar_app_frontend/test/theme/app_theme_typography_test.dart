import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_editor_theme.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Inter weights and license are bundled for offline use', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final inter = manifest
        .cast<Map<String, dynamic>>()
        .singleWhere((font) => font['family'] == 'Inter');
    final fonts = inter['fonts'] as List;
    expect(fonts.map((font) => font['weight']), containsAll([400, 500, 600]));
    for (final font in fonts) {
      final data = await rootBundle.load(font['asset'] as String);
      expect(data.lengthInBytes, greaterThan(10000));
    }
    expect(await rootBundle.loadString('assets/fonts/inter/LICENSE.txt'),
        contains('SIL OPEN FONT LICENSE'));
  });
  for (final brightness in Brightness.values) {
    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.windows
    ]) {
      testWidgets('shared typography roles: $brightness $platform',
          (tester) async {
        final theme = AppTheme.forPlatform(brightness, platform: platform);
        final text = theme.textTheme;
        expect(text.titleLarge!.fontSize, 18);
        expect(text.titleMedium!.fontSize, 14);
        expect(text.bodyMedium!.fontSize, 13);
        expect(text.labelMedium!.fontSize, 12);
        expect(text.labelLarge!.fontWeight, FontWeight.w500);
        final mobile = platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS;
        expect(theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
            mobile ? 48 : 32);
        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          theme.appBarTheme.titleTextStyle
        ]) {
          expect(style?.fontFamily, equals('Inter'));
        }
        for (final style in [
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall
        ]) {
          expect(style?.fontFamily, equals('Inter'));
        }
        final typography = theme.extension<AppTypography>()!;
        expect(typography.accentHeading.fontFamily, equals('Inter'));
        expect(typography.accentText.fontFamily, equals('Inter'));
        expect(typography.buttonText.fontFamily, equals('Inter'));
        expect(typography.buttonText.color, isNull);
      });
    }
    testWidgets('client editor preserves global font roles: $brightness',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme:
            AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
        home: Builder(builder: (context) {
          final editor = clientEditorThemeOf(context);
          expect(editor.textTheme.titleLarge?.fontFamily, equals('Inter'));
          expect(
              editor.appBarTheme.titleTextStyle?.fontFamily, equals('Inter'));
          expect(editor.textTheme.bodyLarge?.fontFamily, equals('Inter'));
          expect(editor.inputDecorationTheme.labelStyle?.fontFamily,
              equals('Inter'));
          return const SizedBox.shrink();
        }),
      ));
    });
  }
  testWidgets('calendar uses shared heading and body fonts', (tester) async {
    expect(buildHeaderStyle(18, Colors.black).textStyle?.fontFamily,
        equals('Inter'));
    final days = buildViewHeaderStyle(12, Colors.black, false);
    expect(days.dateTextStyle?.fontFamily, equals('Inter'));
    expect(days.dayTextStyle?.fontFamily, equals('Inter'));
    expect(
        buildScheduleSettings(18, Colors.white)
            .monthHeaderSettings
            .monthTextStyle
            ?.fontFamily,
        equals('Inter'));
  });
}
