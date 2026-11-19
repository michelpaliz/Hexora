import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/app_theme.dart';

Color _resolveColor(Color? color, Set<WidgetState> states) {
  expect(color, isNotNull);
  return color is WidgetStateColor ? color.resolve(states) : color!;
}

Color _borderColor(InputBorder? border) {
  expect(border, isA<OutlineInputBorder>());
  return (border! as OutlineInputBorder).borderSide.color;
}

void main() {
  test('desktop light form palette uses shared Hexora tokens', () {
    final theme = AppTheme.forPlatform(
      Brightness.light,
      platform: TargetPlatform.windows,
      isWeb: true,
    );
    final input = theme.inputDecorationTheme;

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.cardTheme.color, AppColors.formSection);
    expect(_resolveColor(input.fillColor, const {}), AppColors.inputBackground);
    expect(
      _resolveColor(input.fillColor, const {WidgetState.disabled}),
      const Color(0xFFE7EDF6),
    );
    expect(_borderColor(input.enabledBorder), AppColors.inputBorder);
    expect(_borderColor(input.focusedBorder), AppColors.inputFocus);
    expect(input.floatingLabelBehavior, FloatingLabelBehavior.always);
  });

  test('mobile light form palette keeps the same hierarchy', () {
    final theme = AppTheme.forPlatform(
      Brightness.light,
      platform: TargetPlatform.android,
      isWeb: false,
    );

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.inputDecorationTheme.fillColor, AppColors.inputBackground);
    expect(
      _borderColor(theme.inputDecorationTheme.focusedBorder),
      AppColors.inputFocus,
    );
  });

  test('dark form palette remains unchanged', () {
    final theme = AppTheme.forPlatform(
      Brightness.dark,
      platform: TargetPlatform.windows,
      isWeb: true,
    );

    expect(theme.scaffoldBackgroundColor, AppDarkColors.background);
    expect(theme.inputDecorationTheme.fillColor, AppDarkColors.surface);
    expect(
      _borderColor(theme.inputDecorationTheme.focusedBorder),
      AppDarkColors.primary,
    );
  });
}
