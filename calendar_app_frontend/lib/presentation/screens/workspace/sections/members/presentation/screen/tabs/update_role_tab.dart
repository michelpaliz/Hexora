import 'package:flutter/material.dart';
import 'package:hexora/models/user_model/user.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/add_users_flow/screen/paged_group_role_list.dart';
import 'package:hexora/presentation/utils/roles/group_role/group_role.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class UpdateRolesTab extends StatelessWidget {
  const UpdateRolesTab({
    super.key,
    required this.rolesByUserId,
    required this.membersById,
    required this.assignableRoles,
    required this.canEditRole,
    required this.setRole,
    required this.actorIsOwner,
  });

  final Map<String, GroupRole> rolesByUserId;
  final Map<String, User> membersById;
  final List<GroupRole> assignableRoles;
  final bool Function(String userId) canEditRole;
  final void Function(String userId, GroupRole newRole) setRole;
  final bool actorIsOwner;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    if (rolesByUserId.isEmpty) {
      return Center(child: Text(l.noUserRolesAvailable, style: t.bodyMedium));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: PagedGroupRoleList(
        roles: rolesByUserId,
        membersById: membersById,
        assignableRoles: assignableRoles,
        canEditRole: canEditRole,
        setRole: setRole,
        actorIsOwner: actorIsOwner,
        onRemoveUser: null,
      ),
    );
  }
}
