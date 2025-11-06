import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';

String _titleCaseRole(String r) {
  switch (r.toLowerCase()) {
    case 'owner':
      return 'Owner';
    case 'admin':
      return 'Administrator';
    case 'co-admin':
    case 'coadmin':
      return 'Co-Administrator';
    default:
      return 'Member';
  }
}

extension GroupRoleExtension on Group {
  /// UI-friendly role (Owner / Administrator / Co-Administrator / Member)
  String getRoleForUser(User user) {
    if (ownerId == user.id) return 'Owner';
    final raw = userRoles[user.id]?.toLowerCase() ?? 'member';
    return _titleCaseRole(raw);
  }

  /// Raw role enum for logic ('owner' | 'admin' | 'co-admin' | 'member')
  String getRawRoleForUser(User user) {
    if (ownerId == user.id) return 'owner';
    return (userRoles[user.id]?.toLowerCase() ?? 'member');
  }
}

/// ✅ Utility class for group-related permissions
class GroupPermissionHelper {
  static bool hasPermissions(User user, Group group) {
    final role = group.getRawRoleForUser(user);
    return role == 'owner' || role == 'admin' || role == 'co-admin';
  }
}
