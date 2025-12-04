// lib/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/lists/page_group_role_list.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/widgets/member_role_tile.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class PagedGroupRoleList extends StatefulWidget {
  /// userId -> role
  final Map<String, GroupRole> roles;

  /// userId -> user
  final Map<String, User> membersById;

  /// which roles can be assigned
  final List<GroupRole> assignableRoles;

  /// whether current user can edit a given user’s role
  final bool Function(String userId) canEditRole;

  /// persist role change
  final void Function(String userId, GroupRole newRole) setRole;

  /// whether the actor is an owner (only owners can assign owner)
  final bool actorIsOwner;

  /// optional remove
  final void Function(String userId)? onRemoveUser;

  const PagedGroupRoleList({
    super.key,
    required this.roles,
    required this.membersById,
    required this.assignableRoles,
    required this.canEditRole,
    required this.setRole,
    required this.actorIsOwner,
    this.onRemoveUser,
  });

  @override
  State<PagedGroupRoleList> createState() => _PagedGroupRoleListState();
}

class _PagedGroupRoleListState extends State<PagedGroupRoleList> {
  static const int _pageSize = 20;
  int _visible = _pageSize;
  late Map<String, GroupRole> _localRoles;

  @override
  void initState() {
    super.initState();
    _localRoles = _ensureCoverage(widget.roles);
  }

  @override
  void didUpdateWidget(covariant PagedGroupRoleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRoles(widget.roles, _localRoles) ||
        oldWidget.membersById.length != widget.membersById.length) {
      _localRoles = _ensureCoverage(widget.roles);
    }
  }

  Map<String, GroupRole> _ensureCoverage(Map<String, GroupRole> base) {
    final next = Map<String, GroupRole>.from(base);
    for (final id in widget.membersById.keys) {
      next.putIfAbsent(id, () => GroupRole.member);
    }
    return next;
  }

  bool _sameRoles(Map<String, GroupRole> a, Map<String, GroupRole> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key]?.wire != b[key]?.wire) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // sort by role priority then by display name
    final userIds = _localRoles.keys.toList()
      ..sort((a, b) {
        final rA = _localRoles[a] ?? GroupRole.member;
        final rB = _localRoles[b] ?? GroupRole.member;
        final p = rA.rank.compareTo(rB.rank);
        if (p != 0) return p;
        final nA = widget.membersById[a]?.name ?? '';
        final nB = widget.membersById[b]?.name ?? '';
        return nA.toLowerCase().compareTo(nB.toLowerCase());
      });

    final total = userIds.length;
    final visible = _visible.clamp(0, total);

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l.noUserRolesAvailable, style: t.bodyMedium),
      );
    }

    // quick stats
    final owners = userIds
        .where((id) => (_localRoles[id] ?? GroupRole.member) == GroupRole.owner)
        .length;
    final admins = userIds
        .where((id) => (_localRoles[id] ?? GroupRole.member) == GroupRole.admin)
        .length;
    final coAdmins = userIds
        .where(
            (id) => (_localRoles[id] ?? GroupRole.member) == GroupRole.coAdmin)
        .length;
    final members = total - owners - admins - coAdmins;

    // NOTE: return a Column (not a ListView) to play nice inside outer scroll views
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== Info header (shared) =====
          InfoHeader(
            title: l.tabUpdateRoles,
            subtitle: l.updateRolesHelperText,
            stats: [
              RoleStatChip(
                  role: GroupRole.owner,
                  count: owners,
                  icon: Icons.workspace_premium_rounded),
              RoleStatChip(
                  role: GroupRole.admin,
                  count: admins,
                  icon: Icons.admin_panel_settings_rounded),
              RoleStatChip(
                  role: GroupRole.coAdmin,
                  count: coAdmins,
                  icon: Icons.shield_rounded),
              RoleStatChip(
                  role: GroupRole.member,
                  count: members,
                  icon: Icons.person_rounded),
            ],
          ),
          const SizedBox(height: 12),

          // ===== Cards list (visible page) =====
          for (var i = 0; i < visible; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _UserRoleCard(
                child: MemberRoleTile(
                  userId: userIds[i],
                  user: widget.membersById[userIds[i]],
                  role: _localRoles[userIds[i]] ?? GroupRole.member,
                  rolesByUserId: _localRoles,
                  assignableRoles: widget.actorIsOwner
                      ? widget.assignableRoles
                      : widget.assignableRoles
                          .where((r) => r.wire != 'owner')
                          .toList(),
                  editable: widget.canEditRole(userIds[i]),
                  onRoleChanged: widget.canEditRole(userIds[i])
                      ? (newRole) {
                          setState(() {
                            _localRoles[userIds[i]] = newRole;
                          });
                          widget.setRole(userIds[i], newRole);
                        }
                      : null,
                  onRemove: widget.canEditRole(userIds[i])
                      ? () => widget.onRemoveUser?.call(userIds[i])
                      : null,
                ),
              ),
            ),

          if (visible < total)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.expand_more),
                label:
                    Text('Load more (${total - visible})', style: t.bodyMedium),
                onPressed: () => setState(() => _visible += _pageSize),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pretty card wrapper for each user tile
class _UserRoleCard extends StatelessWidget {
  final Widget child;
  const _UserRoleCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cs.surface,
      elevation: isDark ? 0 : 1.5,
      shadowColor: cs.shadow.withOpacity(.15),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: cs.outlineVariant.withOpacity(.4), width: 1),
        ),
        child: child,
      ),
    );
  }
}
