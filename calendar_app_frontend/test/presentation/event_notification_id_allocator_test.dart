import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/event/model/event.dart';
import 'package:hexora/presentation/features/notifications/event_notification_id_allocator.dart';
import 'package:hexora/presentation/features/notifications/event_notification_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('allocates unique IDs for full event IDs and notification kinds',
      () async {
    final allocator = EventNotificationIdAllocator();

    final ids = await Future.wait(<Future<int>>[
      allocator.idFor(
        eventId: 'event|reminder',
        kind: EventNotificationKind.reminder,
      ),
      allocator.idFor(
        eventId: 'event',
        kind: EventNotificationKind.reminder,
      ),
      allocator.idFor(
        eventId: 'event',
        kind: EventNotificationKind.start,
      ),
    ]);

    expect(ids.toSet(), hasLength(3));
  });

  test('keeps an event notification ID after allocator restart', () async {
    final firstAllocator = EventNotificationIdAllocator();
    final allocated = await firstAllocator.idFor(
      eventId: 'event-1',
      kind: EventNotificationKind.reminder,
    );

    final restartedAllocator = EventNotificationIdAllocator();
    final restored = await restartedAllocator.idFor(
      eventId: 'event-1',
      kind: EventNotificationKind.reminder,
    );

    expect(restored, allocated);
  });

  test('reuses an ID when a reminder replaces an event notification',
      () async {
    final allocator = EventNotificationIdAllocator();
    final original = await allocator.idFor(
      eventId: 'event-1',
      kind: EventNotificationKind.reminder,
    );
    final replacement = await allocator.idFor(
      eventId: 'event-1',
      kind: EventNotificationKind.reminder,
    );

    expect(replacement, original);
  });

  test('cancellation targets the persisted ID', () async {
    final allocator = EventNotificationIdAllocator();
    final event = Event(
      id: 'event-1',
      ownerId: 'owner-1',
      title: 'Reminder',
      startDate: DateTime(2030),
      endDate: DateTime(2030, 1, 1, 1),
    );
    final scheduled = await notifIdFor(event, allocator: allocator);
    MethodCall? cancellation;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      cancellation = call;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await cancelReminderFor(event, idAllocator: allocator);

    expect(cancellation?.method, 'cancel');
    expect(cancellation?.arguments, <String, int>{'id': scheduled});
  });
}
