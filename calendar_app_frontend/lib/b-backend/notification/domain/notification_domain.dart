import 'dart:async';
import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';

class NotificationDomain extends ChangeNotifier {
  List<NotificationUser> _notifications = [];
  List<String> _notificationIds = []; // Store IDs only
  final NotificationApiClient notificationService = NotificationApiClient();
  final _notificationViewModel =
      StreamController<List<NotificationUser>>.broadcast();

  Stream<List<NotificationUser>> get notificationStream =>
      _notificationViewModel.stream;

  List<NotificationUser> get notifications => _notifications;
  List<String> get notificationIds => _notificationIds;

  // Initialize notifications with IDs, fetch full NotificationUser objects
  Future<void> initNotifications(List<String> notificationIds) async {
    _notificationIds = notificationIds;
    _notifications = await _fetchNotificationsByIds(notificationIds);
    _notifications = _sortNotificationsByDate(_notifications);
    _notificationViewModel.add(_notifications);
    notifyListeners();
  }

  Future<List<NotificationUser>> _fetchNotificationsByIds(
      List<String> ids) async {
    // Run requests in parallel
    final futures = ids.map((id) async {
      try {
        final notification = await notificationService.getNotificationById(id);
        return notification;
      } catch (e, st) {
        // Log and skip this ID, but don't fail the whole fetch
        print('⚠️ Failed to fetch $id: $e');
        print(st);
        return null;
      }
    });

    final results = await Future.wait(futures, eagerError: false);
    // Drop nulls (not found / failed)
    return results.whereType<NotificationUser>().toList();
  }

  // Update notification stream
  Future<void> updateNotificationStream(
    List<NotificationUser> notifications,
  ) async {
    _notifications = _sortNotificationsByDate(notifications);
    _notificationViewModel.add(_notifications);
    notifyListeners();
  }

  // Sort notifications by date
  List<NotificationUser> _sortNotificationsByDate(
    List<NotificationUser> notifications,
  ) {
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  // Mark notifications as read, update both locally and on the service level
  Future<void> markAllNotificationsAsRead(UserDomain userDomain) async {
    try {
      List<String> updatedNotificationIds = [];
      for (NotificationUser notification in _notifications) {
        if (!notification.isRead) {
          notification.isRead = true; // Mark as read directly
          await notificationService.updateNotification(notification);
          updatedNotificationIds.add(notification.id);
        }
      }
      _notificationIds = updatedNotificationIds;
      _notifications = await _fetchNotificationsByIds(updatedNotificationIds);
      userDomain.user?.notifications =
          _notificationIds; // Store IDs in user object
      await userDomain.updateUser(userDomain.user!);

      _notificationViewModel.add(_notifications);
      notifyListeners();
    } catch (e) {
      print('Failed to mark notifications as read: $e');
    }
  }

  // Remove notification by index
  Future<bool> removeNotificationByIndex(
    int index,
    UserDomain userDomain,
  ) async {
    if (index < 0 || index >= _notifications.length) {
      return false;
    }

    try {
      NotificationUser notification = _notifications[index];
      _notifications.removeAt(index);
      _notificationIds.remove(notification.id); // Remove the ID

      userDomain.user?.notifications = _notificationIds;
      await userDomain.updateUser(userDomain.user!);

      _notificationViewModel.add(_notifications);
      notifyListeners();

      return true;
    } catch (e) {
      print('Failed to remove notification: $e');
      return false;
    }
  }

  // Remove notification by ID
  Future<bool> removeNotificationById(
    String notificationId,
    UserDomain userDomain,
  ) async {
    try {
      _notificationIds.remove(notificationId);
      _notifications.removeWhere(
        (notification) => notification.id == notificationId,
      );

      userDomain.user?.notifications = _notificationIds;
      await userDomain.updateUser(userDomain.user!);

      _notificationViewModel.add(_notifications);
      notifyListeners();

      return true;
    } catch (e) {
      print('Failed to remove notification: $e');
      return false;
    }
  }

  // Method to update user notification IDs
  Future<void> updateUserNotificationIds(
    List<String> newNotificationIds,
    UserDomain userDomain,
  ) async {
    try {
      // Update the internal list of notification IDs
      _notificationIds = newNotificationIds;

      // Fetch the updated notifications from the service
      _notifications = await _fetchNotificationsByIds(newNotificationIds);

      // Sort the notifications by date
      _notifications = _sortNotificationsByDate(_notifications);

      // Update the current user's notification IDs
      userDomain.user?.notifications = newNotificationIds;

      // Update the user object in the database or state management
      await userDomain.updateUser(userDomain.user!);

      // Update the notification stream with the new notifications
      _notificationViewModel.add(_notifications);

      // Notify listeners to refresh the UI
      notifyListeners();
    } catch (e) {
      devtools.log('Failed to update user notification IDs: $e');
    }
  }

  void clearNotifications() {
    _notifications.clear();
    _notificationIds.clear();
    _notificationViewModel.add(_notifications);
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationViewModel.close();
    super.dispose();
  }
}
