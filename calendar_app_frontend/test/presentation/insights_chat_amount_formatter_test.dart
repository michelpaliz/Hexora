import 'package:hexora/presentation/features/shared/widgets/insights_chat_amount_formatter.dart';
import 'package:test/test.dart';

void main() {
  test('formats grouped European amounts with two decimal places', () {
    expect(formatInsightsEuroAmount(1234.5, 'EUR'), '1.234,50 EUR');
    expect(formatInsightsEuroAmount(1234567, 'USD'), '1.234.567,00 USD');
    expect(formatInsightsEuroAmount(-1234.56, 'EUR'), '-1.234,56 EUR');
  });

  test('preserves the existing currency fallback and trimming rules', () {
    expect(formatInsightsEuroAmount(10, ''), '10,00 EUR');
    expect(formatInsightsEuroAmount(10, '  GBP  '), '10,00 GBP');
    expect(
      () => formatInsightsEuroAmount(10, null),
      throwsA(isA<TypeError>()),
    );
  });

  test('returns an empty label for missing amounts', () {
    expect(formatInsightsEuroAmount(null, 'EUR'), isEmpty);
  });
}
