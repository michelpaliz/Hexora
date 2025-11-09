// lib/a-models/enums/group_role.dart

enum GroupRole { member, coAdmin, admin, owner }

extension GroupRoleX on GroupRole {
  /// Canonical wire/string value used by your APIs/DB
  String get wire => switch (this) {
        GroupRole.member => 'member',
        GroupRole.coAdmin => 'co-admin',
        GroupRole.admin => 'admin',
        GroupRole.owner => 'owner',
      };

  /// Parse from various backend/user-provided strings
  static GroupRole from(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'owner':
        return GroupRole.owner;
      case 'co-admin':
      case 'coadmin':
      case 'co_admin':
        return GroupRole.coAdmin;
      case 'admin':
        return GroupRole.admin;
      case 'member':
      default:
        return GroupRole.member;
    }
  }

  /// Optional helpers (useful in guards/UX)
  bool get canManageMembers => switch (this) {
        GroupRole.owner => true,
        GroupRole.admin => true,
        GroupRole.coAdmin => true,
        GroupRole.member => false,
      };

  bool get canManageGroup => switch (this) {
        GroupRole.owner => true,
        GroupRole.admin => true,
        GroupRole.coAdmin => false,
        GroupRole.member => false,
      };

  int get rank => switch (this) {
        GroupRole.owner => 3,
        GroupRole.admin => 2,
        GroupRole.coAdmin => 1,
        GroupRole.member => 0,
      };

  int get priorityAsc => switch (this) {
        GroupRole.owner => 0,
        GroupRole.admin => 1,
        GroupRole.coAdmin => 2,
        GroupRole.member => 3,
      };
  String toWire(GroupRole r) => switch (r) {
        GroupRole.owner => 'owner',
        GroupRole.admin => 'admin',
        GroupRole.coAdmin => 'co-admin',
        GroupRole.member => 'member',
      };
}
