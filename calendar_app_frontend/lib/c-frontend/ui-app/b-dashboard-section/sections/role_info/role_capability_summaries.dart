// lib/c-frontend/ui-app/shared/profile/role_capability_summaries.dart
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Centralizes the short capability bullets shown on the ProfileRoleCard.
class RoleCapabilitySummaries {
  static List<String> forRole(GroupRole role, AppLocalizations l) {
    switch (role) {
      case GroupRole.owner:
        return [
          l.roleOwnerBullet1, // e.g. "Change group settings and features"
          l.roleOwnerBullet2, // "Manage billing"
          l.roleOwnerBullet3, // "Add/remove admins and members"
          l.roleOwnerBullet4, // "See and edit all calendars/events"
          l.roleOwnerBullet5, // "Delete the group"
        ].where((s) => (s).trim().isNotEmpty).toList();

      case GroupRole.admin:
      case GroupRole.coAdmin:
        return [
          l.roleCoAdminBullet1, // "Create/edit/delete events"
          l.roleCoAdminBullet2, // "Manage services, clients"
          l.roleCoAdminBullet3, // "Invite/remove members (limited)"
          l.roleCoAdminBullet4, // "Configure notifications & work hours"
        ].where((s) => (s).trim().isNotEmpty).toList();

      case GroupRole.member:
      return [
          l.roleMemberBullet1, // "See your events"
          l.roleMemberBullet2, // "Mark visits as done"
          l.roleMemberBullet3, // "Add notes"
        ].where((s) => (s).trim().isNotEmpty).toList();
    }
  }
}
