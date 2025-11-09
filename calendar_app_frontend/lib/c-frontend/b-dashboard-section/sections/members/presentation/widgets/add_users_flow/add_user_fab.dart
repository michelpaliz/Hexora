import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/screen/review_user_screen.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:provider/provider.dart';

class AddUsersFab extends StatelessWidget {
  const AddUsersFab({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Add users'),
      backgroundColor: cs.primary,
      foregroundColor: ThemeColors.contrastOn(cs.primary),
      onPressed: () async {
        final repo = context.read<IUserRepository>();
        final vm = context.read<MembersVM>();

        // Push the Review & Roles screen (it opens the bottom sheet for search)
        final result = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => ReviewAndAddUsersScreen(
              currentUser: null,
              group: group,
              userRepository: repo, // interface instance
            ),
          ),
        );

        if (result != null) {
          final users = (result['users'] as List<User>);
          final roles = (result['roles'] as Map<String, String>);

          // TODO: persist via your GroupDomain/repo, e.g.:
          // await context.read<GroupDomain>().groupRepository
          //   .upsertMembers(group.id, users.map((u) => u.id).toList(), roles);

          await vm.refreshAll();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Members updated')));
        }
      },
    );
  }
}
