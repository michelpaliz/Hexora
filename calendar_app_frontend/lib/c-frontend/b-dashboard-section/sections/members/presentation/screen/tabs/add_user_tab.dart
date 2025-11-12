import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/selected_users_list.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
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

    final ctrl = context.watch<AddUserController>();
    final port = context.watch<IGroupEditorPort>();

    final Map<String, GroupRole> rolesByIdOrName = {
      ...port.roles,
      for (final u in ctrl.selectedUsers)
        u.id: ctrl.stagedRoleOf(u.id) ?? GroupRole.member,
    };

    final existingCount = port.membersById.length;
    final stagedCount = ctrl.selectedUsers.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24 + 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info (no trailing action)
          InfoHeader(
            title: l.tabAddUsers,
            subtitle: l.addUsersHelperText,
            stats: [
              StatChip(
                  label: l.membersTitle,
                  count: existingCount,
                  icon: Icons.groups_rounded),
              StatChip(
                  label: l.selectedLabel,
                  count: stagedCount,
                  icon: Icons.person_add_alt_1_rounded),
            ],
          ),

          // Button below the header info
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              onPressed: openPicker,
              label: Text(
                l.addUsersCount(stagedCount),
                style: t.buttonText.copyWith(
                  color: Theme.of(context).canvasColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant.withOpacity(0.5), height: 1),
          const SizedBox(height: 16),

          // Selected chips/list
          Text(
            l.selectedLabel,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SelectedUsersList(
            users: ctrl.selectedUsers,
            rolesByIdOrName: rolesByIdOrName,
            onRemove: (username) => ctrl.unselect(username),
            onChangeRole: (username, newRole) {
              ctrl.setStagedRoleByUsername(username, newRole);
            },
          ),
        ],
      ),
    );
  }
}
