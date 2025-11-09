import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/lists/page_group_role_list.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class UpdateRolesTab extends StatelessWidget {
  const UpdateRolesTab({
    super.key,
    required this.rolesByUserId,
    required this.membersById,
    required this.assignableRoles,
    required this.canEditRole,
    required this.setRole,
  });

  final Map<String, GroupRole> rolesByUserId;
  final Map<String, User> membersById;
  final List<GroupRole> assignableRoles;
  final bool Function(String userId) canEditRole;
  final void Function(String userId, GroupRole newRole) setRole;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    if (rolesByUserId.isEmpty) {
      return Center(child: Text(l.noUserRolesAvailable, style: t.bodyMedium));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: PagedGroupRoleList(
        roles: rolesByUserId,
        membersById: membersById,
        assignableRoles: assignableRoles,
        canEditRole: canEditRole,
        setRole: setRole,
        onRemoveUser: null,
      ),
    );
  }
}
