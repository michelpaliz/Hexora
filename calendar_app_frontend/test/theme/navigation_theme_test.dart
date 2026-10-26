import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';

void main() {
  test('navigation surface replaces inherited light container colors', () {
    final theme = navigationTheme(ThemeData.light());
    final colors = theme.colorScheme;

    expect(colors.brightness, Brightness.dark);
    expect(colors.surface, AppDarkColors.sidebar);
    expect(colors.surfaceContainerLowest, AppDarkColors.sidebar);
    expect(colors.surfaceContainerLow, AppDarkColors.surface);
    expect(colors.onSurface, AppDarkColors.textPrimary);
    expect(colors.onSurfaceVariant, AppDarkColors.textSecondary);
  });
}
