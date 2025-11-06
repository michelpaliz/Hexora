import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';

/// Initializes and tracks editable state for Group editing screens,
/// without embedded invitations (invites are a separate collection).
class GroupInitializationService {
  final Group group;
  final TextEditingController descriptionController;

  late String groupName;
  late String groupDescription;
  late String imageURL;

  /// Current editable roles (userId -> role, lowercase)
  late Map<String, String> usersRoles;

  /// Snapshot of roles at open time to compute diffs later
  late Map<String, String> _originalRoles;

  GroupInitializationService({
    required this.group,
    required this.descriptionController,
  }) {
    _initialize();
  }

  void _initialize() {
    groupName = group.name;
    groupDescription = group.description;
    imageURL = group.photoUrl ?? '';

    // Roles keyed by userId; normalize to lowercase
    usersRoles = Map<String, String>.fromEntries(
      group.userRoles.entries.map(
        (e) => MapEntry(e.key, (e.value).toLowerCase()),
      ),
    );

    // Ensure owner role is set
    usersRoles[group.ownerId] = 'owner';

    // Snapshot original for diffing
    _originalRoles = Map<String, String>.from(usersRoles);

    // Seed controller
    descriptionController.text = groupDescription;
  }

  // ----------------- Mutations used by UI -----------------

  void setRoleForUserId(String userId, String role) {
    usersRoles[userId] = role.toLowerCase();
  }

  void addUser(User user, {String role = 'member'}) {
    usersRoles[user.id] = role.toLowerCase();
  }

  void removeUserById(String userId) {
    if (userId == group.ownerId) return; // never remove owner here
    usersRoles.remove(userId);
  }

  // ----------------- Diffs used when saving -----------------

  /// Users that appear in `usersRoles` but are not yet members of the group.
  /// These are the ones you likely want to **invite** after saving the group.
  List<String> get newlyInvitedUserIds {
    final currentMembers = group.userIds.toSet();
    // Owner is a member; exclude them just in case
    currentMembers.add(group.ownerId);
    return usersRoles.keys
        .where((uid) => !currentMembers.contains(uid))
        .toList();
  }

  /// Roles that changed compared to when the editor opened.
  /// Use this to build a minimal payload for role updates.
  Map<String, String> get changedRoles {
    final Map<String, String> out = {};
    for (final entry in usersRoles.entries) {
      final uid = entry.key;
      final now = entry.value.toLowerCase();
      final before = _originalRoles[uid]?.toLowerCase();
      if (before == null) {
        // new user in the map (may be invite)
        out[uid] = now;
      } else if (before != now) {
        out[uid] = now;
      }
    }
    return out;
  }

  /// Users removed from the map (you may prevent removal of real members here
  /// or interpret this as "revoke membership" depending on your product rules).
  List<String> get removedUserIds {
    final current = usersRoles.keys.toSet();
    final before = _originalRoles.keys.toSet();
    final removed = before.difference(current).toList();
    // Don’t allow owner removal
    removed.removeWhere((uid) => uid == group.ownerId);
    return removed;
  }
}
