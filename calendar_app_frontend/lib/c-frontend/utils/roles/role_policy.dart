import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';

/// Reusable role/permission policy.
/// You provide a way to resolve a user's role by id, and the policy decides.
class RolePolicy {
  /// Can [actorId] edit [targetId]'s role?
  static bool canEditRole({
    required String actorId,
    required String targetId,
    required String ownerId,
    required GroupRole Function(String userId) roleOf,
  }) {
    // no self-edit
    if (actorId.isEmpty || targetId.isEmpty || actorId == targetId)
      return false;
    // can’t edit the owner
    if (targetId == ownerId) return false;

    final actor = roleOf(actorId);
    final target = roleOf(targetId);

    // strictly higher rank can edit lower rank
    return actor.rank > target.rank;
  }

  /// Which roles can [actorId] assign to [targetId]?
  /// By default, excludes `owner`.
  static List<GroupRole> assignableRoles({
    required String actorId,
    required String targetId,
    required String ownerId,
    required GroupRole Function(String userId) roleOf,
    bool includeOwner = false,
  }) {
    final actor = roleOf(actorId);
    final target = roleOf(targetId);

    final all = <GroupRole>[
      GroupRole.member,
      GroupRole.coAdmin,
      GroupRole.admin,
      if (includeOwner) GroupRole.owner,
    ];

    // You can only assign roles with lower rank than yours,
    // and (optionally) never owner.
    return all.where((r) {
      if (targetId == ownerId && r != GroupRole.owner)
        return false; // owner stays owner
      if (!includeOwner && r == GroupRole.owner) return false;
      return r.rank < actor.rank;
    }).toList();
  }
}
