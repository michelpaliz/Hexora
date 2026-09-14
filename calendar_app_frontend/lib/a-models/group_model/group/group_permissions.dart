import 'package:hexora/a-models/group_model/group/group.dart';

/// Canonical group membership roles used for authorization.
enum GroupMemberRole {
  owner,
  admin,
  coAdmin,
  member;

  static GroupMemberRole fromWire(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'owner':
        return owner;
      case 'admin':
        return admin;
      case 'co-admin':
      case 'coadmin':
        return coAdmin;
      case 'member':
      default:
        return member;
    }
  }

  String get wire => switch (this) {
        owner => 'owner',
        admin => 'admin',
        coAdmin => 'co-admin',
        member => 'member',
      };

  /// Temporary UI label for legacy callers. Do not use for authorization.
  String get displayName => switch (this) {
        owner => 'Owner',
        admin => 'Administrator',
        coAdmin => 'Co-Administrator',
        member => 'Member',
      };
}

/// Shared group role resolution and permission checks.
class GroupPermissions {
  const GroupPermissions._();

  static GroupMemberRole roleFor(Group group, String? userId) {
    if (userId == null || userId.isEmpty) return GroupMemberRole.member;
    if (group.ownerId == userId) return GroupMemberRole.owner;
    return GroupMemberRole.fromWire(group.userRoles[userId]);
  }

  static bool isOwner(Group group, String? userId) =>
      roleFor(group, userId) == GroupMemberRole.owner;

  static bool canManageGroup(Group group, String? userId) {
    switch (roleFor(group, userId)) {
      case GroupMemberRole.owner:
      case GroupMemberRole.admin:
      case GroupMemberRole.coAdmin:
        return true;
      case GroupMemberRole.member:
        return false;
    }
  }

  static bool canAddEvents(Group group, String? userId) =>
      canManageGroup(group, userId);

  static bool canEditGroup(Group group, String? userId) =>
      canManageGroup(group, userId);

  static bool canManageInvoices(Group group, String? userId) =>
      canManageGroup(group, userId);

  static bool canSendInvoiceEmails(Group group, String? userId) {
    final role = roleFor(group, userId);
    return role == GroupMemberRole.owner || role == GroupMemberRole.coAdmin;
  }
}
