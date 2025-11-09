import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

/// `AddUserController` is a state management controller that handles the process of adding a user to a group in a Flutter application.
///
/// This controller is responsible for managing the state of a user addition flow, including searching for users, staging the selection of users, and assigning roles to users.
///
/// The controller uses the `ChangeNotifier` class from Flutter to manage state and can be used with the provider package to keep the UI simple.
///
/// The controller has the following methods:
/// - `_seedRolesFromGroup`: Seeds the `userRoles` map with roles from the group's `userRoles`.
/// - `_loadGroupUsers`: Fetches the user profiles for the group's `userIds` and adds them to the `usersInGroup` list.
/// - `searchUser`: Searches for users based on a query and updates the `searchResults` list.
/// - `addUser`: Adds a user to the `usersInGroup` list, updates the `userRoles` map, and removes the user from the `searchResults` list.
/// - `removeUser`: Removes a user from the `usersInGroup` list and updates the `userRoles` map.
/// - `changeRole`: Changes the role of a user in the `userRoles` map.
/// - `clearResults`: Clears the `searchResults` list.
/// - `_showSnackBar`: Displays a snackbar with a message.
///
/// This controller keeps the UI simple by consolidating the search and staging functionality into a single controller.
/// It allows the UI to present a simple flow for adding users to a group, while still providing the necessary functionality.
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
        final u = await _userRepoInterface.getUserById(id);
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
