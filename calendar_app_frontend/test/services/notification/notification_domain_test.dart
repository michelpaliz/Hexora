import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/services/notification/notification_api_client.dart';
import 'package:hexora/services/notification/utils/result.dart';

class _FakeNotificationApiClient extends NotificationApiClient {
  int activeRequests = 0;
  int maxActiveRequests = 0;

  @override
  Future<GetNotifResult> getNotificationById(String id) async {
    activeRequests++;
    if (activeRequests > maxActiveRequests) {
      maxActiveRequests = activeRequests;
    }
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (id == 'missing') return const NotifNotFound();
      if (id == 'error') return const NotifError('Server error');
      if (id == 'offline') throw Exception('Connection timed out');
      return NotifOk(NotificationUser(
        id: id,
        senderId: 'sender',
        recipientId: 'recipient',
        titleKey: '',
        messageKey: '',
        fallbackTitle: id,
        fallbackMessage: '',
        args: const {},
        timestamp: DateTime.utc(2026, 1, int.parse(id)),
        groupId: 'group',
        category: Category.message,
      ));
    } finally {
      activeRequests--;
    }
  }
}

void main() {
  test('loads successful notifications while limiting concurrent requests',
      () async {
    final api = _FakeNotificationApiClient();
    final domain = NotificationDomain(notificationService: api);
    addTearDown(domain.dispose);

    await domain.initNotifications([
      '1',
      '2',
      'missing',
      '3',
      'error',
      '4',
      'offline',
      '5',
      '6',
    ]);

    expect(domain.notifications.map((item) => item.id),
        ['6', '5', '4', '3', '2', '1']);
    expect(domain.notificationIds.length, 9);
    expect(api.maxActiveRequests, lessThanOrEqualTo(4));
    expect(api.maxActiveRequests, greaterThan(1));
  });
}
