import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_editor_theme.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
          expect(style?.fontFamily, contains('Poppins'));
        }
        for (final style in [
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall
        ]) {
          expect(style?.fontFamily, contains('Manrope'));
        }
        final typography = theme.extension<AppTypography>()!;
        expect(typography.accentHeading.fontFamily, contains('Poppins'));
        expect(typography.accentText.fontFamily, contains('Manrope'));
        expect(typography.buttonText.fontFamily, contains('Manrope'));
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
          expect(editor.textTheme.titleLarge?.fontFamily, contains('Poppins'));
          expect(editor.appBarTheme.titleTextStyle?.fontFamily,
              contains('Poppins'));
          expect(editor.textTheme.bodyLarge?.fontFamily, contains('Manrope'));
          expect(editor.inputDecorationTheme.labelStyle?.fontFamily,
              contains('Manrope'));
          return const SizedBox.shrink();
        }),
      ));
    });
  }
  testWidgets('calendar uses shared heading and body fonts', (tester) async {
    expect(buildHeaderStyle(18, Colors.black).textStyle?.fontFamily,
        contains('Poppins'));
    final days = buildViewHeaderStyle(12, Colors.black, false);
    expect(days.dateTextStyle?.fontFamily, contains('Manrope'));
    expect(days.dayTextStyle?.fontFamily, contains('Manrope'));
    expect(
        buildScheduleSettings(18, Colors.white)
            .monthHeaderSettings
            .monthTextStyle
            ?.fontFamily,
        contains('Poppins'));
  });
}
