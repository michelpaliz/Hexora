import 'dart:developer' as devtools show log;

import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/errors/group_limit_exception.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
// ⛔ remove: import 'package:hexora/services/api/user/user_services.dart';
import 'package:hexora/services/notification/notification_api_client.dart';
import 'package:hexora/services/user/domain/user_domain.dart';

class NotificationViewModel {
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final NotificationDomain notificationDomain;

  // If your notification layer was also split, prefer NotificationRepository.
  final NotificationApiClient notificationService;

  NotificationViewModel({
    required this.userDomain,
    required this.groupDomain,
    required this.notificationDomain,
    required this.notificationService,
  });

  /// ✅ Fetch notifications for a user and update stream
  Future<void> fetchAndUpdateNotifications(User user,
      {bool reportErrors = false}) async {
    final readStateAtStart = {
      for (final n in notificationDomain.notifications) n.id: n.isRead,
    };
    try {
      final fetched = await notificationService.getNotificationsForUser(
        user.userName,
      );
      fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await notificationDomain.applyFetchedNotifications(fetched,
          readStateAtStart: readStateAtStart);
    } catch (e) {
      devtools.log('❌ Error fetching notifications: $e');
      if (reportErrors) rethrow;
    }
  }

  /// ✅ Handle "Accept" response to a group invite/// ✅ Handle "Accept" response to a group invite
  Future<void> handleConfirmation(NotificationUser notification) async {
    try {
      // Use ids directly; user might not have access to group details yet.
      final user = await userDomain.getUserById(notification.recipientId);

      // Accept on backend + hard refresh groups for this user
      await groupDomain.respondToInviteAndRefresh(
        groupId: notification.groupId,
        userId: user.id,
        accepted: true,
        userDomain: userDomain,
      );

      await _removeResolvedInvitation(notification);
    } on GroupLimitException {
      rethrow;
    } catch (e) {
      devtools.log('❌ Error confirming invitation: $e');
      rethrow;
    }
  }

  /// ✅ Handle "Decline" response to a group invite
  Future<void> handleNegation(NotificationUser notification) async {
    try {
      final user = await userDomain.getUserById(notification.recipientId);

      await groupDomain.respondToInviteAndRefresh(
        groupId: notification.groupId,
        userId: user.id,
        accepted: false,
        userDomain: userDomain,
      );

      await _removeResolvedInvitation(notification);
    } catch (e) {
      devtools.log('❌ Error declining invitation: $e');
      rethrow;
    }
  }

  /// ✅ Remove a notification by its index in the local list
  Future<void> removeNotificationByIndex(int index) async {
    final notification = notificationDomain.notifications[index];
    await notificationService.deleteNotification(notification.id);
    await notificationDomain.removeNotificationByIndex(index);
  }

  /// ✅ Remove all notifications for the current user (DB + local)
  Future<void> removeAllNotifications(User user) async {
    try {
      await notificationService.deleteAllMine(); // backend
      notificationDomain.clearNotifications(); // local
      // Optional: re-fetch to ensure sync
      await fetchAndUpdateNotifications(user);
    } catch (e) {
      devtools.log('❌ Error removing all notifications: $e');
      rethrow;
    }
  }

  Future<List<NotificationUser>> fetchNotificationsForGroup(
      String groupId) async {
    try {
      final fetched =
          await notificationService.getNotificationsForGroup(groupId);
      fetched.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return fetched;
    } catch (e) {
      devtools.log('❌ Error fetching group notifications: $e');
      rethrow;
    }
  }

  /// Invitation response is the primary action. Cleanup must never make a
  /// successful accept/decline appear to have failed and invite the user to
  /// submit the same response again.
  Future<void> _removeResolvedInvitation(NotificationUser notification) async {
    try {
      await notificationService.deleteNotification(notification.id);
    } catch (e) {
      devtools.log('Notification cleanup failed after invite response: $e');
    }
    await notificationDomain.removeNotificationById(notification.id);
  }

  Future<void> deleteNotification(NotificationUser notification) async {
    await notificationService.deleteNotification(notification.id);
    await notificationDomain.removeNotificationById(notification.id);
  }

  Future<void> markNotificationAsRead(NotificationUser notification) async {
    if (notification.isRead) return;
    final request = NotificationUser.fromJson(notification.toJson())
      ..isRead = true;
    await notificationService.updateNotification(request);
    notification.isRead = true;

    final updated = notificationDomain.notifications.map((n) {
      if (n.id == notification.id) {
        n.isRead = true;
      }
      return n;
    }).toList();
    await notificationDomain.updateNotificationStream(updated);
  }
}
