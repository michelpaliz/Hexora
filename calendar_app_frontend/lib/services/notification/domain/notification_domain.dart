import 'dart:async';
import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/services/notification/notification_api_client.dart';
import 'package:hexora/services/notification/utils/result.dart';

class NotificationDomain extends ChangeNotifier {
  NotificationDomain({NotificationApiClient? notificationService})
      : notificationService = notificationService ?? NotificationApiClient();

  List<NotificationUser> _notifications = [];
  List<String> _notificationIds = []; // Store IDs only
  final NotificationApiClient notificationService;
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
    const batchSize = 4;
    final notifications = <NotificationUser>[];
    for (var start = 0; start < ids.length; start += batchSize) {
      final batch = ids.skip(start).take(batchSize);
      final results = await Future.wait(batch.map((id) async {
        try {
          final result = await notificationService.getNotificationById(id);
          return switch (result) {
            NotifOk(:final value) => value,
            NotifNotFound() => null,
            NotifError(:final message) => _logFetchFailure(id, message),
          };
        } catch (error) {
          return _logFetchFailure(id, error);
        }
      }));
      notifications.addAll(results.whereType<NotificationUser>());
    }
    return notifications;
  }

  NotificationUser? _logFetchFailure(String id, Object error) {
    devtools.log('Failed to fetch notification $id: $error');
    return null;
  }

  // Update notification stream
  Future<void> updateNotificationStream(
    List<NotificationUser> notifications,
  ) async {
    _notifications = _mergeNotifications(notifications, _notifications);
    _notificationViewModel.add(_notifications);
    notifyListeners();
  }

  /// Apply a complete server refresh while retaining changes made locally
  /// after that request started (socket arrivals, reads and deletions).
  Future<void> applyFetchedNotifications(
    List<NotificationUser> fetched, {
    required Map<String, bool> readStateAtStart,
  }) async {
    final current = {for (final n in _notifications) n.id: n};
    final next = <String, NotificationUser>{};
    for (final n in fetched) {
      if (readStateAtStart.containsKey(n.id) && !current.containsKey(n.id)) {
        continue; // Deleted locally while the request was in flight.
      }
      final local = current[n.id];
      if (local != null &&
          (!readStateAtStart.containsKey(n.id) ||
              local.isRead != readStateAtStart[n.id])) {
        next[n.id] = local;
      } else {
        next[n.id] = n;
      }
    }
    for (final n in current.values) {
      if (!readStateAtStart.containsKey(n.id)) next[n.id] = n;
    }
    _notifications = _sortNotificationsByDate(next.values.toList());
    _notificationIds = next.keys.toList();
    _notificationViewModel.add(_notifications);
    notifyListeners();
  }

  Future<void> addInboundNotification(NotificationUser notification) async {
    final existingIndex =
        _notifications.indexWhere((item) => item.id == notification.id);
    if (existingIndex >= 0) {
      _notifications[existingIndex] = notification;
    } else {
      _notifications.add(notification);
    }

    if (!_notificationIds.contains(notification.id)) {
      _notificationIds.add(notification.id);
    }

    _notifications = _sortNotificationsByDate(_notifications);
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

  List<NotificationUser> _mergeNotifications(
    List<NotificationUser> primary,
    List<NotificationUser> secondary,
  ) {
    final byId = <String, NotificationUser>{};
    for (final notification in secondary) {
      byId[notification.id] = notification;
    }
    for (final notification in primary) {
      byId[notification.id] = notification;
    }
    _notificationIds = byId.keys.toList();
    return _sortNotificationsByDate(byId.values.toList());
  }

  /// Mark all notifications as read on the service and locally.
  /// Returns the updated list of notification IDs so the caller
  /// (e.g. UserDomain) can persist them on the user.
  Future<List<String>> markAllNotificationsAsRead() async {
    try {
      final updatedNotificationIds = <String>[];

      for (final notification in _notifications) {
        if (!notification.isRead) {
          notification.isRead = true; // Mark as read directly
          await notificationService.updateNotification(notification);
        }
        updatedNotificationIds.add(notification.id);
      }

      _notificationIds = updatedNotificationIds;
      _notifications = await _fetchNotificationsByIds(updatedNotificationIds);

      _notifications = _sortNotificationsByDate(_notifications);
      _notificationViewModel.add(_notifications);
      notifyListeners();

      return _notificationIds;
    } catch (e) {
      devtools.log('Failed to mark notifications as read: $e');
      return _notificationIds;
    }
  }

  /// Remove a notification by index. Returns the updated list of IDs
  /// so the caller can persist them on the user.
  Future<List<String>> removeNotificationByIndex(int index) async {
    if (index < 0 || index >= _notifications.length) {
      return _notificationIds;
    }

    try {
      final notification = _notifications[index];
      _notifications.removeAt(index);
      _notificationIds.remove(notification.id); // Remove the ID

      _notifications = _sortNotificationsByDate(_notifications);
      _notificationViewModel.add(_notifications);
      notifyListeners();

      return _notificationIds;
    } catch (e) {
      devtools.log('Failed to remove notification: $e');
      return _notificationIds;
    }
  }

  /// Remove a notification by ID. Returns the updated list of IDs
  /// so the caller can persist them on the user.
  Future<List<String>> removeNotificationById(String notificationId) async {
    try {
      _notificationIds.remove(notificationId);
      _notifications.removeWhere(
        (notification) => notification.id == notificationId,
      );

      _notifications = _sortNotificationsByDate(_notifications);
      _notificationViewModel.add(_notifications);
      notifyListeners();

      return _notificationIds;
    } catch (e) {
      devtools.log('Failed to remove notification: $e');
      return _notificationIds;
    }
  }

  /// Update internal notification state from a new list of IDs.
  /// Caller is responsible for updating the user object in the DB.
  Future<void> updateUserNotificationIds(
      List<String> newNotificationIds) async {
    try {
      // Update the internal list of notification IDs
      _notificationIds = newNotificationIds;

      // Fetch the updated notifications from the service
      _notifications = await _fetchNotificationsByIds(newNotificationIds);

      // Sort the notifications by date
      _notifications = _sortNotificationsByDate(_notifications);

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
