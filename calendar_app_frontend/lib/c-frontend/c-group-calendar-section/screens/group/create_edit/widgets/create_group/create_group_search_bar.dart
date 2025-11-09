import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:provider/provider.dart';

import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';

import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/user/repository/user_repository.dart';

import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/lists/group_selected_user_list.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/search_bar/custome_search_bar.dart';


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

  /// Apply local changes to the ViewModel (no backend writes here).
  void _onConfirmChanges() {
    final vm = widget.controller;

    // 1) Add all selected users to the VM
    for (final u in _controller.usersInGroup) {
      vm.addMember(u);
    }

    // 2) Apply roles from the controller's enum map: userId -> GroupRole
    for (final entry in _controller.userRoles.entries) {
      final userId = entry.key;
      final role = entry.value; // GroupRole
      vm.setRole(userId, role);
    }

    _showSnackBar('✅ Local changes applied.');
  }

  @override
  Widget build(BuildContext context) {
    // If controller not ready yet, show nothing
    if (!mounted) {
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<AddUserController>(
        builder: (context, ctrl, _) {
          // Adapter for GroupSelectedUsersList (expects username -> string role)
          final usernameById = {
            for (final u in ctrl.usersInGroup) u.id: u.userName,
          };
          final rolesByUsername = ctrl.userRoles.map((userId, roleEnum) {
            final key = usernameById[userId] ?? userId; // fallback
            return MapEntry(key, roleEnum.wire); // string wire for the widget
          });

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
                userRoles: rolesByUsername, // username -> string role (wire)
                onRemoveUser: (username) {
                  ctrl.removeUser(username);
                  _showSnackBar('User removed: $username');
                },
                onRoleChanged: (username, newRoleWire) {
                  // Convert wire string -> enum before updating controller
                  ctrl.changeRole(username, GroupRoleX.from(newRoleWire));
                  _showSnackBar('Role updated: $username → $newRoleWire');
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
