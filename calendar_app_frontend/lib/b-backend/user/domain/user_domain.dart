import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
// App config
import 'package:hexora/b-backend/config/api_constants.dart';
// Notifications
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';

class UserDomain extends ChangeNotifier {
  User? _user;

  // ✅ Injected repository interface (no direct instantiation)
  final IUserRepository userRepository;
  final NotificationDomain _notificationDomain;

  final ValueNotifier<User?> currentUserNotifier = ValueNotifier<User?>(null);

  Timer? _avatarRefreshTimer;

  User? get user => _user;

  UserDomain({
    required this.userRepository,
    required NotificationDomain notificationDomain,
    User? user,
  }) : _notificationDomain = notificationDomain {
    if (user != null) {
      setCurrentUser(user);
    }
  }

  Future<String> getAuthToken({bool forceRefresh = false}) {
    return userRepository.getAuthToken(forceRefresh: forceRefresh);
  }

  // ---------- Helpers for other parts of the app ----------
  Future<List<User>> getUsersForGroup(Group group) =>
      userRepository.getUsersForGroup(group);

  // Pass-throughs so existing code compiles
  Future<User> getUserById(String id) => userRepository.getUserById(id);
  Future<User> getUserByUsername(String username) =>
      userRepository.getUserByUsername(username);

  // ---------- User state ----------
  void setCurrentUser(User? user) {
    debugPrint('👤 setCurrentUser called with: $user');
    _stopAvatarRefreshTimer();

    if (user != null) {
      updateCurrentUser(user);

      // If avatars are private, periodically refresh SAS URLs
      if (!ApiConstants.avatarsArePublic) {
        _startAvatarRefreshTimer();
      }
    } else {
      _user = null;
      currentUserNotifier.value = null;
      notifyListeners();
    }
  }

  void updateCurrentUser(User user) {
    _user = user;
    currentUserNotifier.value = user;
    _initNotifications(user);

    // Try an immediate avatar refresh if private blobs
    if (!ApiConstants.avatarsArePublic) {
      refreshUserAvatarUrlIfNeeded();
    }

    notifyListeners();
  }

  void _initNotifications(User user) {
    final notificationIds = user.notifications;
    debugPrint("Initializing notifications: $notificationIds");
    _notificationDomain.initNotifications(notificationIds);
  }

  /// Mark all notifications as read for the current user.
  Future<void> markAllNotificationsAsRead() async {
    if (_user == null) return;

    final updatedIds = await _notificationDomain.markAllNotificationsAsRead();
    final updatedUser = _user!.copyWith(notifications: updatedIds);
    await updateUser(updatedUser);
  }

  /// Remove a notification by index and persist on the user.
  Future<void> removeNotificationByIndex(int index) async {
    if (_user == null) return;

    final updatedIds =
        await _notificationDomain.removeNotificationByIndex(index);
    final updatedUser = _user!.copyWith(notifications: updatedIds);
    await updateUser(updatedUser);
  }

  /// Remove a notification by id and persist on the user.
  Future<void> removeNotificationById(String notificationId) async {
    if (_user == null) return;

    final updatedIds =
        await _notificationDomain.removeNotificationById(notificationId);
    final updatedUser = _user!.copyWith(notifications: updatedIds);
    await updateUser(updatedUser);
  }

  /// Set notification IDs for the user and domain.
  Future<void> setUserNotificationIds(List<String> newNotificationIds) async {
    if (_user == null) return;

    await _notificationDomain.updateUserNotificationIds(newNotificationIds);
    final updatedUser = _user!.copyWith(notifications: newNotificationIds);
    await updateUser(updatedUser);
  }

  Future<void> updateUserFromDB(User? updatedUser) async {
    if (updatedUser == null) return;
    try {
      final fresh = await userRepository.getUserByEmail(updatedUser.email);
      updateCurrentUser(fresh);
    } catch (e) {
      debugPrint('❌ Failed to update user: $e');
    }
  }

  Future<User?> getUser() async {
    if (_user == null) return null;
    try {
      return await userRepository.getUserBySelector(_user!.userName);
    } catch (e) {
      debugPrint('❌ Failed to get user: $e');
      return null;
    }
  }

  Future<bool> updateUser(User updatedUser) async {
    try {
      final saved = await userRepository.updateUser(updatedUser);
      if (_user != null && saved.id == _user!.id) {
        updateCurrentUser(saved);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update user: $e');
      return false;
    }
  }

  // --------------------------
  // Avatar refresh (private)
  // --------------------------
  Future<void> refreshUserAvatarUrlIfNeeded() async {
    if (_user?.photoBlobName == null) return;
    final expiry = _extractExpiryTime(_user!.photoUrl ?? "");
    final now = DateTime.now().toUtc();

    // refresh when missing or expiring soon
    if (expiry == null || expiry.difference(now).inMinutes < 5) {
      try {
        final freshUrl = await userRepository.getFreshAvatarUrl(
          blobName: _user!.photoBlobName!,
        );
        _user = _user!.copyWith(photoUrl: freshUrl);
        currentUserNotifier.value = _user;
        notifyListeners();
        debugPrint('🔄 User avatar URL refreshed');
      } catch (e) {
        debugPrint('❌ Failed to refresh avatar URL: $e');
      }
    }
  }

  DateTime? _extractExpiryTime(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final seParam = uri.queryParameters['se'];
    return seParam != null
        ? DateTime.tryParse(Uri.decodeComponent(seParam))
        : null;
  }

  void _startAvatarRefreshTimer() {
    _avatarRefreshTimer?.cancel();
    _avatarRefreshTimer = Timer.periodic(
      const Duration(minutes: 4),
      (_) => refreshUserAvatarUrlIfNeeded(),
    );
    debugPrint('⏳ Avatar refresh timer started');
  }

  void _stopAvatarRefreshTimer() {
    _avatarRefreshTimer?.cancel();
    _avatarRefreshTimer = null;
    debugPrint('🛑 Avatar refresh timer stopped');
  }

  @override
  void dispose() {
    _stopAvatarRefreshTimer();
    currentUserNotifier.dispose();
    super.dispose();
  }
}

// Utility
String generateCustomId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(
      10,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
