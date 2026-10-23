import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/viewmodels/notifications/notification_view_model.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/invite/domain/invite_domain.dart';
import 'package:hexora/models/groups/invitations/invite.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/services/notification/notification_api_client.dart';

class _User extends Fake implements UserDomain {}

class _Group extends Fake implements GroupDomain {
  int refreshes = 0;
  int legacyResponses = 0;

  @override
  Future<void> refreshGroupsForCurrentUser(UserDomain userDomain) async {
    refreshes++;
  }

  @override
  Future<void> respondToInviteAndRefresh({
    required String groupId,
    required String userId,
    required bool accepted,
    required UserDomain userDomain,
  }) async {
    legacyResponses++;
  }
}

class _Invitation extends Fake implements Invitation {}

class _Invites extends Fake implements InvitationDomain {
  final accepted = <String>[];
  final declined = <String>[];
  bool fail = false;

  @override
  Future<Invitation> acceptOrThrow(String invitationId) async {
    if (fail) throw Exception('accept failed');
    accepted.add(invitationId);
    return _Invitation();
  }

  @override
  Future<Invitation> declineOrThrow(String invitationId,
      {String? reason}) async {
    if (fail) throw Exception('decline failed');
    declined.add(invitationId);
    return _Invitation();
  }
}

class _Api extends NotificationApiClient {
  bool fail = true;
  NotificationUser? submitted;
  String? markedReadId;

  @override
  Future<void> markNotificationRead(String id) async {
    if (fail) throw Exception('read endpoint offline');
    markedReadId = id;
  }

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
  for (final accept in [true, false]) {
    test('notification uses invitation id to ${accept ? 'accept' : 'decline'}',
        () async {
      final api = _Api()..fail = false;
      final notificationDomain = NotificationDomain(notificationService: api);
      addTearDown(notificationDomain.dispose);
      final notification = NotificationUser.fromJson({
        'id': 'notice-modern',
        'recipientId': 'recipient',
        'category': Category.userInvitation.name,
        'titleKey': 'notification.invitation.title',
        if (accept) 'invitationId': 'invite-123',
        'args': {
          if (!accept) 'invitation': {'_id': 'invite-123'},
          'groupId': 'group-from-args',
        },
      });
      await notificationDomain.addInboundNotification(notification);
      final group = _Group();
      final invites = _Invites();
      final vm = NotificationViewModel(
        userDomain: _User(),
        groupDomain: group,
        notificationDomain: notificationDomain,
        notificationService: api,
        invitationDomain: invites,
      );

      if (accept) {
        await vm.handleConfirmation(notification);
      } else {
        await vm.handleNegation(notification);
      }

      expect(invites.accepted, accept ? ['invite-123'] : isEmpty);
      expect(invites.declined, accept ? isEmpty : ['invite-123']);
      expect(group.legacyResponses, 0);
      expect(group.refreshes, 1);
      expect(notification.groupId, 'group-from-args');
      expect(notificationDomain.notifications, isEmpty);
    });
  }

  test('failed invitation response remains available for retry', () async {
    final api = _Api()..fail = false;
    final notificationDomain = NotificationDomain(notificationService: api);
    addTearDown(notificationDomain.dispose);
    final notification = NotificationUser.fromJson({
      'id': 'notice-retry',
      'args': {'invitationId': 'invite-fail'},
    });
    await notificationDomain.addInboundNotification(notification);
    final invites = _Invites()..fail = true;
    final vm = NotificationViewModel(
      userDomain: _User(),
      groupDomain: _Group(),
      notificationDomain: notificationDomain,
      notificationService: api,
      invitationDomain: invites,
    );

    await expectLater(vm.handleConfirmation(notification), throwsException);
    expect(notificationDomain.notifications.single.id, 'notice-retry');
  });

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
    expect(api.markedReadId, 'notice');
    expect(domain.notifications.single.isRead, isTrue);
    await vm.deleteNotification(n);
    expect(domain.notifications, isEmpty);
  });
}
