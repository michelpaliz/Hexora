// lib/c-frontend/ui-app/shared/profile/role_capability_summaries.dart
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Centralizes the short capability bullets shown on the ProfileRoleCard.
List<String> roleCapabilitySummaries(GroupRole role, AppLocalizations l) {
  final key = role.wire.toLowerCase().replaceAll('-', '').replaceAll('_', '');
  if (key == 'owner') {
    return [
      l.roleOwnerBullet1,
      l.roleOwnerBullet2,
      l.roleOwnerBullet3,
      l.roleOwnerBullet4,
      l.roleOwnerBullet5,
    ].where((s) => s.trim().isNotEmpty).toList();
  }
  if (key == 'admin' || key == 'coadmin') {
    return [
      l.roleCoAdminBullet1,
      l.roleCoAdminBullet2,
      l.roleCoAdminBullet3,
      l.roleCoAdminBullet4,
    ].where((s) => s.trim().isNotEmpty).toList();
  }
  // member or unknown defaults
  return [
    l.roleMemberBullet1,
    l.roleMemberBullet2,
    l.roleMemberBullet3,
  ].where((s) => s.trim().isNotEmpty).toList();
}
