import 'package:hexora/presentation/features/shared/widgets/insights_chat_event_request_classifier.dart';
import 'package:test/test.dart';

void main() {
  test('recognizes standalone English and Spanish event words', () {
    for (final text in [
      'Team meeting',
      'Open the CALENDAR',
      'Reunión del equipo',
      'Recordatorio',
    ]) {
      expect(looksLikeInsightsEventCreationRequest(text), isTrue);
    }
  });

  test('requires a time or date hint when only a creation verb matches', () {
    expect(
      looksLikeInsightsEventCreationRequest('Create something tomorrow'),
      isTrue,
    );
    expect(
      looksLikeInsightsEventCreationRequest('Añade algo el 15/09/2026'),
      isTrue,
    );
    expect(looksLikeInsightsEventCreationRequest('Create something'), isFalse);
    expect(looksLikeInsightsEventCreationRequest('Tomorrow at 9'), isFalse);
  });

  test('preserves trimming, casing, accents, and word boundaries', () {
    expect(
      looksLikeInsightsEventCreationRequest('  PROGRAMA algo el MIÉRCOLES  '),
      isTrue,
    );
    expect(looksLikeInsightsEventCreationRequest('calendarized'), isFalse);
    expect(looksLikeInsightsEventCreationRequest(''), isFalse);
    expect(looksLikeInsightsEventCreationRequest('   '), isFalse);
  });
}
