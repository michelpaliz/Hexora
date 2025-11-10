// lib/c-frontend/b-dashboard-section/sections/members/presentation/screen/tabs/add_user_tab.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/selected_users_list.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
// VM → Port
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class AddUsersTab extends StatelessWidget {
  const AddUsersTab({
    super.key,
    required this.openPicker,
  });

  final Future<void> Function() openPicker;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // UI glue (staged selections, search, staged roles, etc.)
    final ctrl = context.watch<AddUserController>();
    // VM truth via port (existing members + their roles)
    final port = context.watch<IGroupEditorPort>();

    // Build the roles map expected by SelectedUsersList:
    // - start with VM (real members) roles
    // - overlay staged roles (or default member) for users in the chips
    final Map<String, GroupRole> rolesByIdOrName = {
      ...port.roles, // userId -> GroupRole for existing members
      for (final u in ctrl.selectedUsers)
        u.id: ctrl.stagedRoleOf(u.id) ?? GroupRole.member, // staged override
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              l.selectedLabel,
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          // Selected Users display -> use pending selections (chips), not VM members
          SelectedUsersList(
            users: ctrl.selectedUsers,
            rolesByIdOrName: rolesByIdOrName, // merged roles
            onRemove: (username) => ctrl.unselect(username),
            onChangeRole: (username, newRole) {
              // Let controller remember staged role (UI-only) until commit
              ctrl.setStagedRoleByUsername(username, newRole);
            },
          ),

          const Spacer(),

          // Open the picker / bottom sheet
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(
                l.addUsersCount(ctrl.selectedUsers.length), // pending count
                style: t.buttonText.copyWith(
                  color: Theme.of(context).canvasColor,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
              ),
              onPressed: openPicker,
            ),
          ),
        ],
      ),
    );
  }
}
