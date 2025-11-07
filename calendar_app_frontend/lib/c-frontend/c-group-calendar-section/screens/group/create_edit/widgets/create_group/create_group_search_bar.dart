import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/user_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/group_editor_state.dart/group_editor_state.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/lists/group_selected_user_list.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/search_bar/custome_search_bar.dart';
import 'package:provider/provider.dart';

class CreateGroupSearchBar extends StatefulWidget {
  final User? user;
  final Group? group;
  final GroupEditorViewModel controller;

  /// Callback triggered when a user is added (for parent preview updates)
  final void Function(User)? onUserPicked;

  const CreateGroupSearchBar({
    super.key,
    required this.user,
    required this.group,
    required this.controller,
    this.onUserPicked,
  });

  @override
  State<CreateGroupSearchBar> createState() => _CreateGroupSearchBarState();
}

class _CreateGroupSearchBarState extends State<CreateGroupSearchBar> {
  late AddUserController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // delay until context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<UserRepository>();

      setState(() {
        _controller = AddUserController(
          currentUser: widget.user,
          group: widget.group,
          userRepositoryInterface: repo,
        );
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Apply local changes to the new ViewModel (no backend writes here).
  void _onConfirmChanges() {
    final vm = widget.controller;

    // 1) Add all selected users to the VM
    for (final u in _controller.usersInGroup) {
      vm.addMember(u);
    }

    // 2) Apply roles. _controller.userRoles is keyed by username (string role).
    for (final entry in _controller.userRoles.entries) {
      final username = entry.key;
      final roleStr = entry.value;

      final user = _firstByUsername(_controller.usersInGroup, username);
      if (user == null) continue;

      vm.setRole(user.id, _toRole(roleStr));
    }

    _showSnackBar("✅ Local changes applied.");
  }

  User? _firstByUsername(List<User> users, String username) {
    for (final u in users) {
      if (u.userName == username) return u;
    }
    return null;
  }

  GroupRole _toRole(String s) {
    switch (s.toLowerCase()) {
      case 'owner':
        return GroupRole.owner;
      case 'co-admin':
      case 'coadmin':
        return GroupRole.coAdmin;
      default:
        return GroupRole.member;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<AddUserController>(
        builder: (context, ctrl, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomSearchBar(
                controller: _searchController,
                onChanged: (query) {
                  if (query.length >= 3) {
                    ctrl.searchUser(query, context);
                  } else {
                    ctrl.clearResults();
                  }
                },
                onSearch: () {
                  if (_searchController.text.length >= 3) {
                    ctrl.searchUser(_searchController.text, context);
                  }
                },
                onClear: () {
                  _searchController.clear();
                  ctrl.clearResults();
                },
              ),
              const SizedBox(height: 10),

              // Search results
              ...ctrl.searchResults.map((username) {
                return ListTile(
                  title: Text(username),
                  trailing: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () async {
                      final addedUser = await ctrl.addUser(username, context);
                      _searchController.clear();

                      if (addedUser != null) {
                        _showSnackBar('User added: $username');
                        widget.onUserPicked?.call(addedUser);
                      } else {
                        _showSnackBar('⚠️ Failed to add user: $username');
                      }
                    },
                  ),
                );
              }),

              const SizedBox(height: 10),

              // Selected users (local to the search sheet)
              GroupSelectedUsersList(
                currentUser: widget.user!,
                usersInGroup: ctrl.usersInGroup,
                userRoles: ctrl.userRoles, // username -> string role (local)
                onRemoveUser: (username) {
                  ctrl.removeUser(username);
                  _showSnackBar('User removed: $username');
                },
                onRoleChanged: (username, newRole) {
                  ctrl.changeRole(username, newRole);
                  _showSnackBar('Role updated: $username → $newRole');
                },
                onConfirmChanges: _onConfirmChanges, // merges into VM
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
