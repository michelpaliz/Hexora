import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
// Avatar (cached, themed, with icon fallback)
import 'package:hexora/c-frontend/utils/image/avatar_utils.dart';
// Global role enum + i18n label helpers
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
// Typography (font family/weights)
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class PagedGroupRoleList extends StatefulWidget {
  /// userId -> role (enum)
  final Map<String, GroupRole> roles;

  /// userId -> user
  final Map<String, User> membersById;

  /// which roles can be assigned via the dropdown (enum list)
  final List<GroupRole> assignableRoles;

  /// whether current user can edit the target user’s role
  final bool Function(String userId) canEditRole;

  /// set role handler
  final void Function(String userId, GroupRole newRole) setRole;

  /// optional remove handler
  final void Function(String userId)? onRemoveUser;

  const PagedGroupRoleList({
    super.key,
    required this.roles,
    required this.membersById,
    required this.assignableRoles,
    required this.canEditRole,
    required this.setRole,
    this.onRemoveUser,
  });

  @override
  State<PagedGroupRoleList> createState() => _PagedGroupRoleListState();
}

class _PagedGroupRoleListState extends State<PagedGroupRoleList> {
  static const int _pageSize = 20;
  int _visible = _pageSize;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);

    final userIds = widget.roles.keys.toList()
      ..sort((a, b) {
        final roleA = widget.roles[a] ?? GroupRole.member;
        final roleB = widget.roles[b] ?? GroupRole.member;

        // ✅ use global priority (no local helper)
        final p = roleA.priorityAsc.compareTo(roleB.priorityAsc);
        if (p != 0) return p;

        final nameA = widget.membersById[a]?.name ?? '';
        final nameB = widget.membersById[b]?.name ?? '';
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

    final total = userIds.length;
    final visible = _visible.clamp(0, total);

    if (total == 0) {
      return Text(loc.noUserRolesAvailable, style: typo.bodyMedium);
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible,
          itemBuilder: (_, i) {
            final userId = userIds[i];
            final role = widget.roles[userId] ?? GroupRole.member;
            final user = widget.membersById[userId];
            final editable = widget.canEditRole(userId);

            return _MemberTile(
              userId: userId,
              role: role,
              user: user,
              editable: editable,
              assignableRoles: widget.assignableRoles,
              onRoleChanged: (newRole) => widget.setRole(userId, newRole),
              onRemove:
                  editable ? () => widget.onRemoveUser?.call(userId) : null,
            );
          },
        ),
        if (visible < total)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.expand_more),
              label: Text('Load more (${total - visible})',
                  style: typo.bodyMedium),
              onPressed: () => setState(() => _visible += _pageSize),
            ),
          ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String userId;
  final GroupRole role;
  final User? user;
  final bool editable;
  final List<GroupRole> assignableRoles;
  final ValueChanged<GroupRole> onRoleChanged;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.userId,
    required this.role,
    required this.user,
    required this.editable,
    required this.assignableRoles,
    required this.onRoleChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final name = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : (user?.userName ?? 'Unknown');

    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

          // ✅ unified avatar util (no local avatar logic)
          leading: AvatarUtils.profileAvatar(
            context,
            user?.photoUrl,
            radius: 20,
          ),

          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            user?.email ?? user?.userName ?? userId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.bodySmall,
          ),

          trailing: SizedBox(
            width: 220,
            child: Align(
              alignment: Alignment.centerRight,
              child: editable
                  ? _RoleSelector(
                      value: role,
                      // ensure current value appears even if not in assignableRoles
                      options: {...assignableRoles, role}.toList(),
                      onChanged: onRoleChanged,
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleLabelOf(context, role), // ✅ global label
                        style: typo.bodySmall.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),

          onLongPress: onRemove,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final GroupRole value;
  final List<GroupRole> options;
  final ValueChanged<GroupRole> onChanged;

  const _RoleSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final outline = Theme.of(context).colorScheme.outlineVariant;

    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<GroupRole>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          items: options.map((r) {
            return DropdownMenuItem<GroupRole>(
              value: r,
              child: Text(
                roleLabelOf(context, r), // ✅ global label again
                style: typo.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null && v != value) onChanged(v);
          },
        ),
      ),
    );
  }
}
