import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';

/// Title-case helper for display (optional)
String _titleCaseRole(String r) {
  switch (r.toLowerCase()) {
    case 'owner':
      return 'Owner';
    case 'admin':
      return 'Admin';
    case 'co-admin':
    case 'coadmin':
      return 'Co-Admin';
    default:
      return 'Member';
  }
}

/// Extension to resolve the user's role in a group (by userId)
extension GroupRoleExtension on Group {
  /// Returns normalized role in **Title Case** for UI (Owner/Admin/Co-Admin/Member).
  String getRoleForUser(User user) {
    if (ownerId == user.id) return 'Owner';
    final raw = userRoles[user.id]?.toLowerCase() ?? 'member';
    return _titleCaseRole(raw);
  }

  /// If you sometimes need the raw enum value instead of title-cased UI text.
  String getRawRoleForUser(User user) {
    if (ownerId == user.id) return 'owner';
    return (userRoles[user.id]?.toLowerCase() ?? 'member');
  }
}

/// Helper class for permission checks
class GroupPermissionHelper {
  static bool canAddEvents(User user, Group group) {
    final role = group.getRawRoleForUser(user);
    return _hasEditRights(role);
  }

  static bool canEditGroup(User user, Group group) {
    final role = group.getRawRoleForUser(user);
    return _hasEditRights(role);
  }

  static bool isOwner(User user, Group group) {
    return group.getRawRoleForUser(user) == 'owner';
  }

  /// Edit rights for owner/admin/co-admin; members are read-only.
  static bool _hasEditRights(String role) {
    switch (role) {
      case 'owner':
      case 'admin':
      case 'co-admin':
        return true;
      default:
        return false;
    }
  }
}
