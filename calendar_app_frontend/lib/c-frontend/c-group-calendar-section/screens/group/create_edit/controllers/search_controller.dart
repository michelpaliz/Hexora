import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/repository/user_repository.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class GroupSearchController extends ChangeNotifier {
  final User? currentUser;
  final Group? group;
  final UserRepository _userRepo;

  GroupSearchController({
    required this.currentUser,
    required this.group,
    required UserRepository userRepository,
  }) : _userRepo = userRepository {
    // Seed creator as default member list + role (owner)
    if (currentUser != null) {
      usersInGroup = [currentUser!];
      userRoles[currentUser!.id] = 'owner'; // keyed by userId
    }

    if (group != null) {
      _seedRolesFromGroup(); // seed from group.userRoles
      _loadGroupUsers(); // fetch User profiles for group.userIds
    }
  }

  // Local state
  List<User> usersInGroup = [];

  /// 🔑 role map: userId -> role (lowercase: 'owner' | 'admin' | 'co-admin' | 'member')
  Map<String, String> userRoles = {};

  /// We keep results as simple usernames for the search UI
  List<String> searchResults = [];

  // ---------- Seeders / Loaders ----------
  void _seedRolesFromGroup() {
    if (group?.userRoles != null) {
      userRoles.addAll(group!.userRoles.map(
        (k, v) => MapEntry(k, (v).toLowerCase()),
      ));
    }
  }

  Future<void> _loadGroupUsers() async {
    if (group == null) return;
    try {
      for (final id in group!.userIds) {
        final u = await _userRepo.getUserById(id);
        if (!usersInGroup.any((x) => x.id == u.id)) {
          usersInGroup.add(u);
        }
      }
      // Ensure owner role is set even if not present in userRoles
      if (group!.ownerId.isNotEmpty) {
        userRoles[group!.ownerId] = 'owner';
      }
      notifyListeners();
    } catch (_) {
      // swallow; UI can still function with partial data
    }
  }

  // ---------- Search / Add / Remove ----------
  Future<void> searchUser(String query, BuildContext context) async {
    final q = query.trim();
    if (q.length < 3) {
      clearResults();
      return;
    }
    try {
      final results = await _userRepo.searchUsernames(q.toLowerCase());
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
      final user = await _userRepo.getUserByUsername(username);

      // prevent duplicates by id or username
      if (usersInGroup.any((u) => u.id == user.id || u.userName == username)) {
        return null;
      }

      usersInGroup.add(user);
      userRoles[user.id] = 'member'; // default role
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
      userRoles.remove(username); // legacy safety
    }
    notifyListeners();
  }

  void changeRole(String username, String newRole) {
    final u = usersInGroup.firstWhere(
      (x) => x.userName == username,
      orElse: () => User.empty(),
    );
    if (u.id.isNotEmpty) {
      userRoles[u.id] = newRole.toLowerCase();
    } else {
      userRoles[username] = newRole.toLowerCase();
    }
    notifyListeners();
  }

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
