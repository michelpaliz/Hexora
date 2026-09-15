import 'package:hexora/presentation/features/shared/widgets/insights_chat_message_presentation.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';
import 'package:test/test.dart';

void main() {
  test('recognizes only the existing action-token shapes', () {
    expect(looksLikeInsightsActionToken(' __menu__:finance '), isTrue);
    expect(looksLikeInsightsActionToken('__back__:root'), isTrue);
    expect(looksLikeInsightsActionToken('__anchored_income'), isTrue);
    expect(looksLikeInsightsActionToken('__custom:value'), isTrue);
    expect(looksLikeInsightsActionToken('__custom'), isFalse);
    expect(looksLikeInsightsActionToken('menu:finance'), isFalse);
  });

  test('maps raw action tokens while preserving ordinary text', () {
    expect(
      visibleInsightsTextForRawValue(
        '__menu__:finance',
        isUser: true,
        isEs: true,
      ),
      'Opcion seleccionada',
    );
    expect(
      visibleInsightsTextForRawValue(
        '__back__:root',
        isUser: true,
        isEs: false,
      ),
      'Option selected',
    );
    expect(
      visibleInsightsTextForRawValue(
        '__anchored_income',
        isUser: false,
        isEs: true,
      ),
      'Procesando opcion...',
    );
    expect(
      visibleInsightsTextForRawValue(
        '__custom:value',
        isUser: false,
        isEs: false,
      ),
      'Processing option...',
    );
    expect(
      visibleInsightsTextForRawValue('  visible  ', isUser: true, isEs: false),
      '  visible  ',
    );
    expect(
      visibleInsightsTextForRawValue('   ', isUser: true, isEs: false),
      '',
    );
  });

  test('preserves message display-text precedence and structured text', () {
    InsightsChatMessage message({
      required bool isUser,
      required String text,
      String? displayText,
    }) {
      return InsightsChatMessage(
        isUser: isUser,
        text: text,
        displayText: displayText,
        timestamp: DateTime.utc(2026, 9, 15),
      );
    }

    expect(
      visibleInsightsMessageText(
        message(
          isUser: false,
          text: '__menu__:finance',
          displayText: '  Visible label  ',
        ),
        isEs: false,
      ),
      'Visible label',
    );
    expect(
      visibleInsightsMessageText(
        message(
          isUser: false,
          text: '  Structured answer  ',
          displayText: 'Visible label',
        ),
        isEs: false,
        preserveStructuredAssistantText: true,
      ),
      'Structured answer',
    );
    expect(
      visibleInsightsMessageText(
        message(isUser: true, text: '__menu__:finance'),
        isEs: false,
        preserveStructuredAssistantText: true,
      ),
      'Option selected',
    );
  });
}
