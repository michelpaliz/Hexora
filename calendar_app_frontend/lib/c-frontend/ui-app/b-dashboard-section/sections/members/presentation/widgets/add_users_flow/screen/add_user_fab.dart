// lib/c-frontend/.../widgets/add_user_fab.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/screen/review_user_screen.dart';
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
        final result = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => const ReviewAndAddUsersScreen(),
          ),
        );

        if (result == null) return;

        final users = result['users'] as List<User>?;
        final roles = result['roles'] as Map<String, String>?;

        // Persist roles via dedicated endpoint; persist new userIds via updateGroup if needed
        if (users != null || roles != null) {
          final gd = context.read<GroupDomain>();
          final repo = gd.groupRepository;
          final userDomain = context.read<UserDomain>();

          // Build an updated snapshot for immediate UI (even before refresh)
          final mergedRoles = {...group.userRoles, ...?roles};
          final mergedIds = <String>{
            ...group.userIds,
            if (users != null) ...users.map((u) => u.id),
          }.toList();

          // Optimistically push snapshot so UI updates instantly
          gd.currentGroup = group.copyWith(
            userIds: mergedIds,
            userRoles: mergedRoles,
          );
          gd.userRoles.value = mergedRoles;

          // 🔹 Apply role changes individually
          if (roles != null) {
            for (final entry in roles.entries) {
              final userId = entry.key;
              final desiredWire = entry.value; // already from backend list
              final currentWire = group.userRoles[userId];

              if (currentWire != desiredWire) {
                await repo.setUserRoleInGroup(
                  groupId: group.id,
                  userId: userId,
                  roleWire: desiredWire,
                );
              }
            }
          }

          // 🔹 If there are new users, update group membership & roles snapshot
          if (users != null && users.isNotEmpty) {
            final updatedGroup = group.copyWith(
              userIds: mergedIds,
              userRoles: mergedRoles,
            );

            await repo.updateGroup(updatedGroup);
          }

          // 🔹 Refresh domain cache/stream and current group
          await gd.refreshGroupsForCurrentUser(userDomain);
          try {
            final fresh = await repo.getGroupById(group.id);
            gd.currentGroup = fresh;
            gd.userRoles.value = Map<String, String>.from(fresh.userRoles);
            // Trigger listeners if they rely on users list
            gd.usersInGroup.value = gd.usersInGroup.value;
          } catch (_) {
            // fallback to merged snapshot for immediate UI
            gd.currentGroup = group.copyWith(
              userIds: mergedIds,
              userRoles: mergedRoles,
            );
            gd.userRoles.value = mergedRoles;
          }
        }

        // 🔹 Refresh members VM so UI reflects latest state
        await context.read<MembersVM>().refreshAll();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Members updated')),
        );
      },
    );
  }
}
