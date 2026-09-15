import 'package:hexora/presentation/features/shared/widgets/insights_chat_event_assistant.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';
import 'package:test/test.dart';

void main() {
  InsightsChatMessage message(Map<String, dynamic>? eventAssistant) {
    return InsightsChatMessage(
      isUser: false,
      text: 'Event response',
      timestamp: DateTime.utc(2026, 9, 15),
      eventAssistant: eventAssistant,
    );
  }

  test('coerces assistant, preview, and event payload maps', () {
    final value = message({
      'status': ' ready_to_create ',
      'preview': <Object, Object>{
        'eventPayload': <Object, Object>{'clientId': 'client-1'},
      },
    });

    expect(insightsEventAssistantForMessage(value)?['status'],
        ' ready_to_create ');
    expect(insightsEventPreviewForMessage(value), {
      'eventPayload': <Object, Object>{'clientId': 'client-1'},
    });
    expect(insightsEventPayloadForMessage(value), {'clientId': 'client-1'});
    expect(insightsEventStatus(value), 'ready_to_create');
    expect(insightsEventAssistantForMessage(message(null)), isNull);
  });

  test('preserves strict cancellation and creation flags', () {
    final ready = message({'canCreate': true});
    final cancelled = message({'canCreate': true, 'cancelled': true});
    final stringFlags = message({'canCreate': 'true', 'cancelled': 'true'});

    expect(insightsEventCanCreate(ready), isTrue);
    expect(insightsEventCanCreate(cancelled), isFalse);
    expect(insightsEventIsCancelled(cancelled), isTrue);
    expect(insightsEventCanCreate(stringFlags), isFalse);
    expect(insightsEventIsCancelled(stringFlags), isFalse);
  });

  test('detects only active clarification requests', () {
    expect(
      insightsEventHasPendingClarification(
        message({'status': 'needs_clarification'}),
      ),
      isTrue,
    );
    expect(
      insightsEventHasPendingClarification(
        message({'status': 'needs_clarification', 'cancelled': true}),
      ),
      isFalse,
    );
    expect(insightsEventHasPendingClarification(null), isFalse);
  });

  test('detects missing client or service selections and labels', () {
    InsightsChatMessage selection({
      String clientId = 'client-1',
      String serviceId = 'service-1',
      List<dynamic> missing = const [],
    }) {
      return message({
        'preview': {
          'missing': missing,
          'eventPayload': {
            'clientId': clientId,
            'primaryServiceId': serviceId,
          },
        },
      });
    }

    expect(
      insightsEventShouldPromptForClientAndService(selection()),
      isFalse,
    );
    expect(
      insightsEventShouldPromptForClientAndService(selection(clientId: '')),
      isTrue,
    );
    expect(
      insightsEventShouldPromptForClientAndService(selection(serviceId: '')),
      isTrue,
    );
    expect(
      insightsEventShouldPromptForClientAndService(
        selection(missing: [' Cliente ', 'SERVICIO']),
      ),
      isTrue,
    );
    expect(
      insightsEventShouldPromptForClientAndService(message(const {})),
      isFalse,
    );
  });

  test('normalizes event string lists with the existing permissive rules', () {
    expect(insightsEventStringList('client'), isEmpty);
    expect(
      insightsEventStringList([' client ', null, '', 2]),
      ['client', '2'],
    );
  });
}
