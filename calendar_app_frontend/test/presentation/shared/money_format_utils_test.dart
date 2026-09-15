import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/utils/formatting/money_format_utils.dart';

void main() {
  group('shared money formatting', () {
    test('normalizes European and US separators without changing decimals', () {
      expect(normalizeMoneyInput(' 1.234,56 '), '1234.56');
      expect(normalizeMoneyInput('1,234.56'), '1234.56');
      expect(normalizeMoneyInput('1 234,56'), '1234.56');
      expect(normalizeMoneyInput('-12,50'), '-12.50');
      expect(normalizeMoneyInput('1,234,567'), '1234567');
      expect(normalizeMoneyInput('12.50'), '12.50');
    });

    test('parses amounts and preserves missing or invalid values', () {
      expect(parseFlexibleMoney(125), 125.0);
      expect(parseFlexibleMoney('1.234,56'), 1234.56);
      expect(parseFlexibleMoney('1,234.56'), 1234.56);
      expect(parseFlexibleMoney(null), isNull);
      expect(parseFlexibleMoney(''), isNull);
      expect(parseFlexibleMoney('invalid'), isNull);
    });

    test('keeps Spanish display formatting and caller-supplied fallbacks', () {
      expect(formatMoneyEu('1,234.56'), '1.234,56');
      expect(formatMoneyEu(0), '0,00');
      expect(formatMoneyEu(-12.5), '-12,50');
      expect(formatMoneyEu(null), '');
      expect(formatMoneyEu('invalid', fallback: '—'), '—');
    });
  });
}
