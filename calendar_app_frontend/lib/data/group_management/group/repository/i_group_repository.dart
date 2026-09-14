import 'dart:io';

import 'package:hexora/models/calendar/calendar.dart';
import 'package:hexora/models/permissions/group_permissions_response.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/models/group/group_business_hours.dart';
import 'package:hexora/models/group/role_meta.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/features/dashboard/sections/members/presentation/domain/models/members_count.dart';

/// Supplies an access token (async-friendly)
typedef TokenSupplier = Future<String> Function();

/// Abstraction for the domain-facing Group repository.
abstract class IGroupRepository {
  // Streams (Single source of truth for groups by user)
  Stream<List<Group>> userGroups$(String userId);
  Future<void> refreshUserGroupsByIds(String userId, List<String> groupIds);

  // CRUD + queries
  Future<Group> createGroup(Group group);
  Future<Group> getGroupById(String groupId);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<List<Group>> getGroupsByUser(String userName);
  Future<void> leaveGroup(String userId, String groupId);

  Future<void> respondToInvite({
    required String groupId,
    required String userId,
    required bool accepted,
  });

  Future<MembersCount> getMembersCount(String groupId, {String? mode});
  Future<Map<String, dynamic>> getGroupMembersMeta(String groupId);
  Future<List<User>> getGroupMemberProfiles(String groupId,
      {List<String>? ids});
  Future<Calendar> getCalendarById(String calendarId);

  // Media
  Future<void> uploadAndCommitGroupPhoto({
    required String groupId,
    required File file,
  });

  Future<Group> setBusinessHours(
    String groupId,
    GroupBusinessHours hours,
  );

  /// Update a single member role.
  Future<void> setUserRoleInGroup({
    required String groupId,
    required String userId,
    required String roleWire,
  });

  /// Fetch supported group roles (wire values) from backend.
  Future<List<String>> getGroupRoles();

  /// Fetch role + permission definitions for a group.
  Future<GroupPermissionsResponse> getGroupPermissions(String groupId);

  /// Send an invitation to join this group.
  Future<void> sendGroupInvitation({
    required String groupId,
    required String userId,
    required String roleWire,
  });

  /// Fetch the full role-change history for a group member.
  /// Returns entries newest-first.
  Future<List<RoleHistoryEntry>> getMemberRoleHistory(
      String groupId, String userId);

  // Lifecycle
  void dispose();
}
