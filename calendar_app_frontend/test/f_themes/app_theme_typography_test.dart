import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light and dark themes initialize with Hexora font families', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.textTheme.titleLarge?.fontFamily, contains('Poppins'));
      expect(theme.textTheme.bodyMedium?.fontFamily, contains('Manrope'));
      expect(theme.textTheme.labelLarge?.fontFamily, contains('Manrope'));
    }
  });
}
