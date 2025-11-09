import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class PagedGroupRoleList extends StatefulWidget {
  final Map<String, GroupRole> roles; // userId -> role
  final Map<String, User> membersById; // userId -> user
  final List<GroupRole> assignableRoles;
  final bool Function(String userId) canEditRole;
  final void Function(String userId, GroupRole newRole) setRole;
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

  int _priority(GroupRole r) => r.priorityAsc;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    final userIds = widget.roles.keys.toList()
      ..sort((a, b) {
        final roleA = widget.roles[a] ?? GroupRole.member;
        final roleB = widget.roles[b] ?? GroupRole.member;
        final p = _priority(roleA).compareTo(_priority(roleB));
        if (p != 0) return p;

        final nameA = widget.membersById[a]?.name ?? '';
        final nameB = widget.membersById[b]?.name ?? '';
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });

    final total = userIds.length;
    final visible = _visible.clamp(0, total);

    if (total == 0) return Text(l.noUserRolesAvailable, style: t.bodyMedium);

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

            return _memberTile(
              context: context,
              userId: userId,
              role: role,
              user: user,
              editable: editable,
              roles: widget.assignableRoles,
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
              label: Text(l.loadMore(total - visible), style: t.bodyMedium),
              onPressed: () => setState(() => _visible += _pageSize),
            ),
          ),
      ],
    );
  }

  Widget _memberTile({
    required BuildContext context,
    required String userId,
    required GroupRole role,
    required User? user,
    required bool editable,
    required List<GroupRole> roles,
    required ValueChanged<GroupRole> onRoleChanged,
    required VoidCallback? onRemove,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final name = user?.name.isNotEmpty == true
        ? user!.name
        : user?.userName ?? 'Unknown';

    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: (user?.photoUrl?.isNotEmpty ?? false)
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: (user?.photoUrl?.isEmpty ?? true)
                ? Text(name[0].toUpperCase(), style: t.bodyMedium)
                : null,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            user?.email ?? user?.userName ?? userId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall,
          ),
          trailing: SizedBox(
            width: 200,
            child: Align(
              alignment: Alignment.centerRight,
              child: editable
                  ? _RoleSelector(
                      value: role,
                      options: {...roles, role}.toList(),
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
                        roleLabelOf(context, role),
                        style: t.bodySmall.copyWith(
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
    final t = AppTypography.of(context);

    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<GroupRole>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          items: options.map((r) {
            return DropdownMenuItem<GroupRole>(
              value: r,
              child: Text(roleLabelOf(context, r), style: t.bodyMedium),
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
