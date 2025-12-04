import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';

/// Reusable role/permission policy using backend-driven roles.
class RolePolicy {
  /// Can [actorId] edit [targetId]'s role?
  static bool canEditRole({
    required String actorId,
    required String targetId,
    required String ownerId,
    required GroupRole Function(String userId) roleOf,
  }) {
    if (actorId.isEmpty || targetId.isEmpty || actorId == targetId) {
      return false;
    }
    if (targetId == ownerId) return false;

    final actor = roleOf(actorId);
    final target = roleOf(targetId);
    return actor.rank > target.rank;
  }

  /// Which roles can [actorId] assign to [targetId]?
  /// Provide [availableRoles] from backend (fallback handled by caller).
  static List<GroupRole> assignableRoles({
    required String actorId,
    required String targetId,
    required String ownerId,
    required GroupRole Function(String userId) roleOf,
    required List<GroupRole> availableRoles,
    bool includeOwner = false,
  }) {
    final actor = roleOf(actorId);
    final target = roleOf(targetId);

    return availableRoles.where((r) {
      final key = _sanitize(r.wire);
      if (!includeOwner && key == 'owner') return false;
      if (targetId == ownerId && key != 'owner') return false;
      return r.rank < actor.rank;
    }).toList();
  }

  static String _sanitize(String v) =>
      v.toLowerCase().replaceAll('-', '').replaceAll('_', '').trim();
}
