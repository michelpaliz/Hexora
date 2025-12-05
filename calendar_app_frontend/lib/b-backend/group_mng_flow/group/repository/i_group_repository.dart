import 'dart:io';

import 'package:hexora/a-models/group_model/calendar/calendar.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/group/group_business_hours.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';

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

  /// Send an invitation to join this group.
  Future<void> sendGroupInvitation({
    required String groupId,
    required String userId,
    required String roleWire,
  });

  // Lifecycle
  void dispose();
}
