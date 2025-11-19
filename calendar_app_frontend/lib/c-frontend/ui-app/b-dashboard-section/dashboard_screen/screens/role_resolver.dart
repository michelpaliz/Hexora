// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/role_resolver.dart
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';

/// Central place to figure out *my* role in a group.
class RoleResolver {
  static Future<GroupRole> resolve({
    required Group group,
    required UserDomain userDomain,
  }) async {
    // 1) Prefer a direct backend call if available.
    try {
      // If your backend exposes this, uncomment and use:
//    final raw = await userDomain.getMyRoleInGroup(group.id);
//    return GroupRoleX.from(raw);

      // 2) Otherwise infer from the Group instance.
      final uid = await userDomain.user!.id;

      // Common patterns; adjust to your Group model shape:
      final ownerId = _tryString(() => (group as dynamic).ownerId);
      if (ownerId == uid) return GroupRole.owner;

      // Some backends expose a single "roleByUserId" map
      final Map<String, dynamic>? rolesByUser =
          _tryMap(() => (group as dynamic).rolesByUser);
      if (rolesByUser != null && rolesByUser.containsKey(uid)) {
        return GroupRoleX.from('${rolesByUser[uid]}');
      }

      // Or split lists:
      final adminIds = _tryStringList(() => (group as dynamic).adminIds);
      final coAdminIds = _tryStringList(() => (group as dynamic).coAdminIds);
      final moderatorIds =
          _tryStringList(() => (group as dynamic).moderatorIds);

      if (adminIds.contains(uid)) return GroupRole.admin;
      if (coAdminIds.contains(uid)) return GroupRole.coAdmin;
      if (moderatorIds.contains(uid))
        return GroupRole.coAdmin; // treat as co-admin
    } catch (_) {
      // swallow and fall through
    }
    return GroupRole.member;
  }

  static String? _tryString(String? Function() f) {
    try {
      final v = f();
      return v is String ? v : null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _tryMap(Map<String, dynamic>? Function() f) {
    try {
      final v = f();
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  static List<String> _tryStringList(List<String>? Function() f) {
    try {
      final v = f();
      return (v ?? const []).whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }
}
