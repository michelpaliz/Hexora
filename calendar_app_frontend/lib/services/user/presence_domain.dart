import 'package:hexora/services/groups/event/socket/socket_manager.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/user_model/user.dart';

/// Enum for user roles
enum UserRole { admin, coAdmin, member }

/// Convert role string from DB to UserRole enum
UserRole parseUserRole(String? roleString) {
  switch (roleString?.toLowerCase()) {
    case 'administrator':
    case 'admin':
      return UserRole.admin;
    case 'co-administrator':
    case 'coadmin':
      return UserRole.coAdmin;
    case 'member':
    default:
      return UserRole.member;
  }
}

/// Updated UserPresence with role
class UserPresence {
  final String userId;
  final String userName;
  final String photoUrl;
  final bool isOnline;
  final UserRole role;

  UserPresence({
    required this.userId,
    required this.userName,
    required this.photoUrl,
    required this.isOnline,
    required this.role,
  });
}

class PresenceDomain extends ChangeNotifier {
  bool _listening = false;
  bool hasReceivedPresence = false;

  // Presence belongs to the signed-in session, not a single calendar route.
  void listenToSocket() {
    if (_listening) return;
    _listening = true;
    SocketManager().on('presence:update', (data) {
      if (data is List) updatePresenceList(data);
    });
  }

  @override
  void dispose() {
    if (_listening) SocketManager().off('presence:update');
    super.dispose();
  }

  final Map<String, UserPresence> _onlineUsers = {}; // userId -> UserPresence
  final Map<String, User> _knownUsers = {}; // from DB

  /// Simpler update method with no role
  void updatePresenceList(List<dynamic> data) {
    final next = <String, UserPresence>{};
    for (final user in data) {
      if (user is! Map) continue;
      final id = user['userId']?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final known = _knownUsers[id];
      next[id] = UserPresence(
        userId: id,
        userName: user['userName']?.toString() ?? known?.userName ?? 'Unknown',
        photoUrl: user['photoUrl']?.toString() ?? known?.photoUrl ?? '',
        isOnline: true,
        role: UserRole.member,
      );
    }
    _onlineUsers
      ..clear()
      ..addAll(next);
    hasReceivedPresence = true;
    notifyListeners();
  }

  void setKnownUsers(List<User> users) {
    for (final user in users) {
      final id = user.id.toString().trim();
      _knownUsers[id] = user;
      debugPrint("ðŸ§  Cached known user: $id (${user.userName})");
    }
    notifyListeners();
  }

  /// Inject role mapping from group: username -> role string
  List<UserPresence> getPresenceForGroup(
    List<String> userIds,
    Map<String, String> groupRoles,
  ) {
    return userIds.map((id) {
      final normalizedId = id.toString().trim();
      final isOnline = _onlineUsers.containsKey(normalizedId);
      final onlinePresence = _onlineUsers[normalizedId];

      final knownUser = _knownUsers[normalizedId];
      final userName =
          onlinePresence?.userName ?? knownUser?.userName ?? "Unknown";
      final photoUrl = onlinePresence?.photoUrl ?? knownUser?.photoUrl ?? "";

      final rawRole =
          groupRoles[normalizedId] ?? groupRoles[userName] ?? 'member';
      final role = parseUserRole(rawRole);

      return UserPresence(
        userId: normalizedId,
        userName: userName,
        photoUrl: photoUrl,
        isOnline: isOnline,
        role: role,
      );
    }).toList();
  }
}
