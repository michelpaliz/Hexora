import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/role_policy.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class AddUserController extends ChangeNotifier {
  final User? currentUser;
  final Group? group;
  final IUserRepository _userRepoInterface;

  AddUserController({
    required this.currentUser,
    required this.group,
    required IUserRepository userRepositoryInterface,
  }) : _userRepoInterface = userRepositoryInterface {
    // Seed creator as default member list + role (owner)
    if (currentUser != null) {
      usersInGroup = [currentUser!];
      userRoles[currentUser!.id] = GroupRole.owner; // enum
    }

    if (group != null) {
      _seedRolesFromGroup(); // seed from group.userRoles (strings -> enum)
      _loadGroupUsers(); // fetch User profiles for group.userIds
    }
  }

  // Local state
  List<User> usersInGroup = [];

  /// 🔑 role map: userId -> role (enum)
  Map<String, GroupRole> userRoles = {};

  /// We keep results as simple usernames for the search UI
  List<String> searchResults = [];

  // ---------- Seeders / Loaders ----------
  void _seedRolesFromGroup() {
    if (group?.userRoles != null) {
      // group.userRoles is Map<String, String> (wire). Convert -> enum.
      userRoles.addAll(group!.userRoles.map(
        (k, v) => MapEntry(k, GroupRoleX.from(v)),
      ));
    }
    // ensure owner
    if ((group?.ownerId ?? '').isNotEmpty) {
      userRoles[group!.ownerId] = GroupRole.owner;
    }
  }

  Future<void> _loadGroupUsers() async {
    if (group == null) return;
    try {
      for (final id in group!.userIds) {
        final u = await _userRepoInterface.getUserById(id);
        if (!usersInGroup.any((x) => x.id == u.id)) {
          usersInGroup.add(u);
        }
      }
      // ensure owner flag even if backend map missed it
      if (group!.ownerId.isNotEmpty) {
        userRoles[group!.ownerId] = GroupRole.owner;
      }
      notifyListeners();
    } catch (_) {
      // swallow; UI can still function with partial data
    }
  }

  // ---------- EDIT ROLES --------------
  GroupRole _roleOfUserId(String userId) {
    // Prefer staged enum; fallback from group strings; else member.
    return userRoles[userId] ??
        (group?.userRoles[userId] != null
            ? GroupRoleX.from(group!.userRoles[userId])
            : (group?.ownerId == userId ? GroupRole.owner : GroupRole.member));
  }

  bool canEditRole(String targetUserId) {
    final me = currentUser?.id ?? '';
    final ownerId = group?.ownerId ?? '';
    return RolePolicy.canEditRole(
      actorId: me,
      targetId: targetUserId,
      ownerId: ownerId,
      roleOf: _roleOfUserId,
    );
  }

  List<GroupRole> assignableRolesFor(String targetUserId) {
    final me = currentUser?.id ?? '';
    final ownerId = group?.ownerId ?? '';
    return RolePolicy.assignableRoles(
      actorId: me,
      targetId: targetUserId,
      ownerId: ownerId,
      roleOf: _roleOfUserId,
      includeOwner: false,
    );
  }

  // ---------- Search / Add / Remove ----------
  Future<void> searchUser(String query, BuildContext context) async {
    final q = query.trim();
    if (q.length < 3) {
      clearResults();
      return;
    }
    try {
      final results = await _userRepoInterface.searchUsernames(q.toLowerCase());
      final existingUsernames = usersInGroup.map((u) => u.userName).toSet();
      searchResults =
          results.where((name) => !existingUsernames.contains(name)).toList();
      notifyListeners();
    } catch (e) {
      searchResults = [];
      notifyListeners();
      _showSnackBar(context, 'Error searching user');
    }
  }

  Future<User?> addUser(String username, BuildContext context) async {
    try {
      final user = await _userRepoInterface.getUserByUsername(username);

      // prevent duplicates by id or username
      if (usersInGroup.any((u) => u.id == user.id || u.userName == username)) {
        return null;
      }

      usersInGroup.add(user);
      userRoles[user.id] = GroupRole.member; // default role (enum)
      searchResults.remove(username);

      notifyListeners();
      return user;
    } catch (e) {
      _showSnackBar(context, 'Error adding user');
      return null;
    }
  }

  void removeUser(String username) {
    final removed = usersInGroup.firstWhere(
      (u) => u.userName == username,
      orElse: () => User.empty(),
    );
    if (removed.id.isNotEmpty) {
      usersInGroup.removeWhere((u) => u.id == removed.id);
      userRoles.remove(removed.id);
    } else {
      usersInGroup.removeWhere((u) => u.userName == username);
      userRoles.remove(username); // legacy safety if map was keyed by username
    }
    notifyListeners();
  }

  /// Change role by username (called by your UI)
  void changeRole(String username, GroupRole newRole) {
    final u = usersInGroup.firstWhere(
      (x) => x.userName == username,
      orElse: () => User.empty(),
    );
    if (u.id.isNotEmpty) {
      userRoles[u.id] = newRole;
    } else {
      // legacy key path (username)
      userRoles[username] = newRole;
    }
    notifyListeners();
  }

  // ---------- Boundary helpers (strings for backend) ----------
  /// When you need to pass roles to APIs that expect strings:
  Map<String, String> get rolesAsWire =>
      userRoles.map((k, r) => MapEntry(k, r.wire));

  void clearResults() {
    if (searchResults.isEmpty) return;
    searchResults.clear();
    notifyListeners();
  }

  // ---------- UI helper ----------
  void _showSnackBar(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    final bg = ThemeColors.containerBg(context);
    final onBg = ThemeColors.textPrimary(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: TextStyle(
            color: onBg,
            fontWeight: FontWeight.w700,
          ),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: ThemeColors.contrastOn(cs.primary),
          backgroundColor: cs.primary,
          onPressed: () {},
        ),
      ),
    );
  }
}
