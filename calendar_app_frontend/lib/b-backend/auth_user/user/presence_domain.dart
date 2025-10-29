import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';

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
  final Map<String, UserPresence> _onlineUsers = {}; // userId -> UserPresence
  final Map<String, User> _knownUsers = {}; // from DB

  /// Simpler update method with no role
  void updatePresenceList(List<dynamic> data) {
    debugPrint("📥 updatePresenceList called with: ${data.length} users");
    _onlineUsers.clear();

    for (final user in data) {
      final rawId = user['userId'];
      final id = rawId.toString().trim(); // normalize

      final presence = UserPresence(
        userId: id,
        userName: user['userName'],
        photoUrl: user['photoUrl'],
        isOnline: true,
        role: UserRole.member, // Temporarily default to member (role set later)
      );

      _onlineUsers[id] = presence;
      debugPrint("✅ Online user added: $id (${user['userName']})");
    }

    debugPrint("🧠 Final online user IDs: ${_onlineUsers.keys.toList()}");
    notifyListeners();
  }

  void setKnownUsers(List<User> users) {
    for (final user in users) {
      final id = user.id.toString().trim();
      _knownUsers[id] = user;
      debugPrint("🧠 Cached known user: $id (${user.userName})");
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

      final rawRole = groupRoles[userName] ?? 'member';
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
