import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/event_notification_tap_handler.dart';

void main() {
  final event = Event(
    id: 'event-1',
    title: 'Reminder event',
    startDate: DateTime(2026, 1, 1, 9),
    endDate: DateTime(2026, 1, 1, 10),
    ownerId: 'user-1',
  );

  test('routes an authenticated reminder tap to its event', () async {
    String? requestedEventId;
    Event? routedEvent;
    final handler = EventNotificationTapHandler(
      isAuthenticated: () => true,
      findEvent: (eventId) async {
        requestedEventId = eventId;
        return event;
      },
      showEventDetails: (selectedEvent) {
        routedEvent = selectedEvent;
      },
    );

    await handler.handlePayload(' event-1 ');

    expect(requestedEventId, 'event-1');
    expect(routedEvent, same(event));
  });

  test('ignores notification taps without an authenticated event ID', () async {
    var lookups = 0;
    final handler = EventNotificationTapHandler(
      isAuthenticated: () => false,
      findEvent: (_) async {
        lookups++;
        return event;
      },
      showEventDetails: (_) {},
    );

    await handler.handlePayload('event-1');
    await handler.handlePayload('  ');

    expect(lookups, 0);
  });

  test('keeps the current screen when the tapped event is unavailable', () async {
    var routed = false;
    var unavailable = false;
    final handler = EventNotificationTapHandler(
      isAuthenticated: () => true,
      findEvent: (_) async => null,
      showEventDetails: (_) {
        routed = true;
      },
      onEventUnavailable: () => unavailable = true,
    );

    await handler.handlePayload('deleted-event');

    expect(routed, isFalse);
    expect(unavailable, isTrue);
  });
}
