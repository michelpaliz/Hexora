// lib/c-frontend/.../controller/add_user_controller.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/widgets/snack_bar.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AddUserController extends ChangeNotifier {
  final IGroupEditorPort port; // ← talk to VM via the port

  AddUserController({required this.port});

  // UI-only state
  final List<User> _selectedUsers = []; // pending chips
  List<User> get selectedUsers => List.unmodifiable(_selectedUsers);

  List<String> _searchResults = []; // usernames for list UI
  List<String> get searchResults => List.unmodifiable(_searchResults);

  final Map<String, User> _searchCache = {}; // username(lower) -> User

  // ===== Search =====
// ===== Search =====
  Future<void> searchUser(String query, BuildContext context) async {
    final q = query.trim();
    if (q.isEmpty) {
      clearResults();
      return;
    }

    try {
      final users = await port.searchUsers(q);

      _searchCache.clear();
      for (final u in users) {
        final name = u.userName;
        if (name.isNotEmpty) {
          _searchCache[name.toLowerCase()] = u;
        }
      }

      // ✅ assign to the backing field, not the getter
      _searchResults =
          users.map((u) => u.userName).whereType<String>().toList();

      notifyListeners();
    } catch (_) {
      // ✅ same here
      _searchResults = [];
      notifyListeners();
      HexoraSnackBar.show(
        context: context,
        message: 'Error searching user',
        translatedMessage: AppLocalizations.of(context)?.errorSearchingUser,
        actionLabel: AppLocalizations.of(context)?.ok ?? 'OK',
      );
    }
  }

  // Future<void> searchUser(String query, BuildContext context) async {
  //   final l = AppLocalizations.of(context);
  //   final q = query.trim();
  //   if (q.isEmpty) {
  //     clearResults();
  //     return;
  //   }

  //   try {
  //     final users = await port.searchUsers(q);
  //     final pending =
  //         _selectedUsers.map((u) => u.userName.toLowerCase()).toSet();

  //     _searchCache.clear();
  //     final usernames = <String>[];
  //     for (final u in users) {
  //       final name = u.userName;
  //       final lower = name.toLowerCase();
  //       _searchCache[lower] = u;
  //       if (!pending.contains(lower)) {
  //         usernames.add(name);
  //       }
  //     }
  //     _searchResults = usernames;
  //     notifyListeners();
  //   } catch (_) {
  //     _searchResults = [];
  //     notifyListeners();
  //     HexoraSnackBar.show(
  //       context: context,
  //       message: 'Error searching user',
  //       translatedMessage: l?.errorSearchingUser,
  //       actionLabel: l?.ok ?? 'OK',
  //     );
  //   }
  // }

  // ===== Stage add/remove =====
  Future<User?> addUser(String username, BuildContext context) async {
    final l = AppLocalizations.of(context);
    final lower = username.toLowerCase();
    final user = _searchCache[lower];

    if (user == null) {
      HexoraSnackBar.show(
        context: context,
        message: 'User not found',
        translatedMessage: l?.userNotFound,
        actionLabel: l?.ok ?? 'OK',
      );
      return null;
    }

    // don’t allow adding someone who is already a real member
    final alreadyMember = port.membersById.containsKey(user.id);
    if (alreadyMember) {
      HexoraSnackBar.show(
        context: context,
        message: 'User is already a member',
        translatedMessage: l?.userAlreadyAdded,
        actionLabel: l?.ok ?? 'OK',
      );
      return null;
    }

    // don’t allow duplicates in pending
    if (_selectedUsers.any((u) => u.id == user.id)) {
      HexoraSnackBar.show(
        context: context,
        message: 'User already in selection',
        translatedMessage: l?.userAlreadyPending,
        actionLabel: l?.ok ?? 'OK',
      );
      return null;
    }

    _selectedUsers.add(user);
    _searchResults.remove(username);
    notifyListeners();
    return user;
  }

  void unselect(String username) {
    _selectedUsers.removeWhere((u) => u.userName == username);
    notifyListeners();
  }

  // ===== Roles (delegate to VM) =====
  void changeRole(String userId, GroupRole newRole) {
    port.setRole(userId, newRole);
    notifyListeners(); // VM already notified; this keeps UI chips in sync if needed
  }

  // ===== Commit staged users into VM =====
  void commitSelected(BuildContext context) {
    if (_selectedUsers.isEmpty) return;

    for (final u in _selectedUsers) {
      port.addMember(u); // VM owns truth
      // Optionally set default member role (VM already defaults to member)
      // port.setRole(u.id, GroupRole.member);
    }

    final count = _selectedUsers.length;
    _selectedUsers.clear();
    notifyListeners();

    final l = AppLocalizations.of(context);
    HexoraSnackBar.show(
      context: context,
      message: 'Selected users added',
      translatedMessage: l?.selectedCommitted(count),
      actionLabel: l?.ok ?? 'OK',
    );
  }

  // ===== Helpers =====
  void clearResults() {
    _searchResults = [];
    _searchCache.clear();
    notifyListeners();
  }

  // In AddUserController

// UI-only staged roles before commit
  final Map<String, GroupRole> _stagedRolesByUserId = {};

  GroupRole? stagedRoleOf(String userId) => _stagedRolesByUserId[userId];

  void setStagedRoleByUsername(String username, GroupRole role) {
    final u = _selectedUsers.firstWhere(
      (x) => x.userName == username,
      orElse: () => User.empty(),
    );
    if (u.id.isEmpty) return;
    _stagedRolesByUserId[u.id] = role;
    notifyListeners();
  }

// // When committing staged users, also apply any staged roles to the VM:
//   void commitSelected(BuildContext context) {
//     if (_selectedUsers.isEmpty) return;

//     for (final u in _selectedUsers) {
//       port.addMember(u);
//       final r = _stagedRolesByUserId[u.id] ?? GroupRole.member;
//       port.setRole(u.id, r);
//     }

//     _selectedUsers.clear();
//     _stagedRolesByUserId.clear();
//     notifyListeners();

//     final l = AppLocalizations.of(context);
//     HexoraSnackBar.show(
//       context: context,
//       message: 'Selected users added',
//       translatedMessage: l?.selectedCommitted(_selectedUsers.length),
//       actionLabel: l?.ok ?? 'OK',
//     );
//   }
}
