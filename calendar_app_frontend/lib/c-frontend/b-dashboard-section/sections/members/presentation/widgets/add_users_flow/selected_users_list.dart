import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class SelectedUsersList extends StatelessWidget {
  const SelectedUsersList({
    super.key,
    required this.users,
    required this.rolesByIdOrName,
    required this.onRemove,
    required this.onChangeRole,
  });

  final List<User> users;
  final Map<String, String>
      rolesByIdOrName; // userId -> role (or username -> role)
  final void Function(String username) onRemove;
  final void Function(String username, String role) onChangeRole;

  static const _roles = <String>['owner', 'admin', 'co-admin', 'member'];

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
                    'member',
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
  final String role;
  final VoidCallback onRemove;
  final void Function(String role) onChangeRole;

  static const _roles = <String>['owner', 'admin', 'co-admin', 'member'];

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
            child: DropdownButton<String>(
              value: _roles.contains(role) ? role : 'member',
              borderRadius: BorderRadius.circular(12),
              items: _roles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      ))
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
