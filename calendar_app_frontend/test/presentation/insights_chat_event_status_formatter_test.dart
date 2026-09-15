import 'package:hexora/presentation/features/shared/widgets/insights_chat_event_status_formatter.dart';
import 'package:test/test.dart';

void main() {
  test('maps known event statuses in English', () {
    expect(
        insightsEventStatusLabel('ready_to_create', false), 'Ready to create');
    expect(
      insightsEventStatusLabel('needs_clarification', false),
      'Needs clarification',
    );
    expect(insightsEventStatusLabel('created', false), 'Created');
    expect(insightsEventStatusLabel('error', false), 'Error');
    expect(insightsEventStatusLabel('not_event', false), 'Not an event');
  });

  test('maps known event statuses in Spanish', () {
    expect(
      insightsEventStatusLabel('ready_to_create', true),
      'Listo para crear',
    );
    expect(
      insightsEventStatusLabel('needs_clarification', true),
      'Necesita aclaracion',
    );
    expect(insightsEventStatusLabel('created', true), 'Creado');
    expect(insightsEventStatusLabel('error', true), 'Error');
    expect(insightsEventStatusLabel('not_event', true), 'No es evento');
  });

  test('preserves empty and unknown status fallbacks', () {
    expect(insightsEventStatusLabel('', false), 'Event');
    expect(insightsEventStatusLabel('', true), 'Evento');
    expect(insightsEventStatusLabel('custom_status', false), 'custom_status');
    expect(insightsEventStatusLabel(' created ', true), ' created ');
  });
}
