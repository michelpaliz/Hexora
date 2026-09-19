import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/viewmodels/notifications/notification_view_model.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/services/notification/notification_api_client.dart';

class _User extends Fake implements UserDomain {}

class _Group extends Fake implements GroupDomain {}

class _Api extends NotificationApiClient {
  bool fail = true;
  NotificationUser? submitted;
  @override
  Future<NotificationUser> updateNotification(NotificationUser n) async {
    submitted = n;
    if (fail) throw Exception('offline');
    return n;
  }

  @override
  Future<bool> deleteNotification(String id) async {
    if (fail) throw Exception('offline');
    return true;
  }
}

void main() {
  test('failed read and delete preserve notification and allow retry',
      () async {
    final api = _Api();
    final domain = NotificationDomain(notificationService: api);
    addTearDown(domain.dispose);
    final n = NotificationUser.fromJson({'id': 'notice'});
    await domain.addInboundNotification(n);
    final vm = NotificationViewModel(
        userDomain: _User(),
        groupDomain: _Group(),
        notificationDomain: domain,
        notificationService: api);
    await expectLater(vm.markNotificationAsRead(n), throwsException);
    expect(n.isRead, isFalse);
    expect(api.submitted!.isRead, isTrue);
    await expectLater(vm.deleteNotification(n), throwsException);
    expect(domain.notifications.single.id, n.id);
    api.fail = false;
    await vm.markNotificationAsRead(n);
    expect(domain.notifications.single.isRead, isTrue);
    await vm.deleteNotification(n);
    expect(domain.notifications, isEmpty);
  });
}
