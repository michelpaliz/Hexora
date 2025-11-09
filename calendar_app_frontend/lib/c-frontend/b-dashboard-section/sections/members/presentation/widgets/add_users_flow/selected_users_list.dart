import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/c-frontend/utils/enums/group_role/group_role.dart';
// If you added a UI l10n extension (optional):
// import 'package:hexora/c-frontend/l10n/group_role_labels.dart';

class SelectedUsersList extends StatelessWidget {
  const SelectedUsersList({
    super.key,
    required this.users,
    required this.rolesByIdOrName,
    required this.onRemove,
    required this.onChangeRole,
  });

  final List<User> users;

  /// userId -> GroupRole (or username -> GroupRole)
  final Map<String, GroupRole> rolesByIdOrName;

  final void Function(String username) onRemove;

  /// Callback now passes a GroupRole instead of String
  final void Function(String username, GroupRole role) onChangeRole;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Selected',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ThemeColors.textSecondary(context),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final u in users)
              _UserChip(
                user: u,
                role: rolesByIdOrName[u.id] ??
                    rolesByIdOrName[u.userName] ??
                    GroupRole.member,
                onRemove: () => onRemove(u.userName),
                onChangeRole: (r) => onChangeRole(u.userName, r),
              ),
          ],
        ),
      ],
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({
    required this.user,
    required this.role,
    required this.onRemove,
    required this.onChangeRole,
  });

  final User user;
  final GroupRole role;
  final VoidCallback onRemove;
  final void Function(GroupRole role) onChangeRole;

  // Roles you want selectable in the UI (order as you like)
  static const List<GroupRole> _availableRoles = <GroupRole>[
    GroupRole.member,
    GroupRole.coAdmin,
    GroupRole.admin,
    GroupRole.owner,
  ];

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        child: Text(
          user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
        ),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('@${user.userName}'),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<GroupRole>(
              value: _availableRoles.contains(role) ? role : GroupRole.member,
              borderRadius: BorderRadius.circular(12),
              items: _availableRoles
                  .map(
                    (r) => DropdownMenuItem<GroupRole>(
                      value: r,
                      child: Text(_roleLabel(context, r)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChangeRole(v);
              },
            ),
          ),
        ],
      ),
      deleteIcon: const Icon(Icons.close),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelPadding: const EdgeInsets.only(right: 4, left: 4),
      padding: const EdgeInsets.only(left: 4),
    );
  }
}

/// Simple label for now. If you have the l10n extension, replace with `role.labelOf(context)`.
String _roleLabel(BuildContext context, GroupRole r) {
  // Prefer your UI/l10n extension if available:
  // return r.labelOf(context);

  // Fallback human labels:
  switch (r) {
    case GroupRole.owner:
      return 'Owner';
    case GroupRole.admin:
      return 'Administrator';
    case GroupRole.coAdmin:
      return 'Co-administrator';
    case GroupRole.member:
      return 'Member';
  }
}
