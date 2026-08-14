import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/all_data/table/statements_all_data_table_theme.dart';

void main() {
  double contrastRatio(Color foreground, Color background) {
    final lighter =
        foreground.computeLuminance() > background.computeLuminance()
            ? foreground
            : background;
    final darker = identical(lighter, foreground) ? background : foreground;
    return (lighter.computeLuminance() + 0.05) /
        (darker.computeLuminance() + 0.05);
  }

  test('dark table variants use a readable cool-blue palette', () {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );
    final standard = StatementsTableTheme.light(colorScheme);
    final elevated = StatementsTableTheme.softDark(colorScheme);

    for (final theme in [standard, elevated]) {
      expect(theme.headerBg.computeLuminance(), lessThan(0.08));
      expect(theme.rowBg.computeLuminance(), lessThan(0.04));
      expect(contrastRatio(theme.headerText, theme.headerBg), greaterThan(7));
      expect(contrastRatio(theme.textPrimary, theme.rowBg), greaterThan(7));
      expect(theme.chipBg.computeLuminance(), lessThan(0.06));
      expect(theme.amountPositive.b, greaterThan(theme.amountPositive.r));
    }

    expect(standard.headerBg, isNot(const Color(0xFFF8FAFC)));
    expect(standard.rowHover, isNot(standard.rowBg));
    expect(standard.rowSelected, isNot(standard.rowBg));
  });
}
