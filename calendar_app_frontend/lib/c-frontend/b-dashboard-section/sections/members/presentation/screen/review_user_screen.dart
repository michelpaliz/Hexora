// review_and_add_users_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/add_user_bottom_sheet.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/selected_users_list.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/c-frontend/utils/enums/group_role/group_role.dart';
import 'package:provider/provider.dart';

class ReviewAndAddUsersScreen extends StatelessWidget {
  const ReviewAndAddUsersScreen({
    super.key,
    required this.currentUser,
    required this.group,
    required this.userRepository,
  });

  final User? currentUser;
  final Group group;
  final IUserRepository userRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddUserController(
        currentUser: currentUser,
        group: group,
        userRepositoryInterface: userRepository,
      ),
      child: const _ReviewScaffold(),
    );
  }
}

class _ReviewScaffold extends StatelessWidget {
  const _ReviewScaffold();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<AddUserController>();

    // 🔁 Adapt Map<String, String> -> Map<String, GroupRole>
    final rolesEnum = ctrl.userRoles.map(
      (k, v) =>
          MapEntry(k, GroupRoleX.from(v)), // v like 'owner' | 'admin' | ...
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members — Review & Roles'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop({
                'users': ctrl.usersInGroup,
                'roles': ctrl.userRoles, // still strings for backend/next step
              });
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: ThemeColors.contrastOn(cs.primary),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: SelectedUsersList(
          users: ctrl.usersInGroup,
          rolesByIdOrName: rolesEnum, // ✅ now Map<String, GroupRole>
          onRemove: (u) => ctrl.removeUser(u),
          onChangeRole: (u, r) => ctrl.changeRole(u, r.wire),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('Add users (${ctrl.usersInGroup.length})'),
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<AddUserController>(),
              child: const AddUsersBottomSheet(),
            ),
          );
        },
      ),
    );
  }
}
