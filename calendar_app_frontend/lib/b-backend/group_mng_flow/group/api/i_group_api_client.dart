import 'package:hexora/a-models/group_model/calendar/calendar.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/group/group_business_hours.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';

abstract class IGroupApiClient {
  Future<Group> createGroup(Group group, String token);
  Future<Group> getGroupById(String id, String token);
  Future<bool> updateGroup(Group group, String token);
  Future<void> deleteGroup(String id, String token);
  Future<void> leaveGroup(String userId, String groupId, String token);
  Future<List<Group>> getGroupsByUser(String userName, String token);
  Future<void> respondToInvite({
    required String groupId,
    required String userId,
    required bool accepted,
    required String token,
  });
  Future<MembersCount> getMembersCount(String groupId, String token,
      {String? mode});
  Future<Map<String, dynamic>> getGroupMembersMeta(
      String groupId, String token);
  Future<List<Map<String, dynamic>>> getGroupMemberProfiles(
    String groupId,
    String token, {
    List<String>? ids,
  });
  Future<Calendar> getCalendarById(String calendarId, String token);
  Future<Group> setBusinessHours(
    String groupId,
    GroupBusinessHours hours,
    String token,
  );

  /// Update a single member's role within a group.
  Future<void> setUserRoleInGroup({
    required String groupId,
    required String userId,
    required String roleWire,
    required String token,
  });

  /// Fetch supported group roles from backend (wire strings).
  Future<List<String>> getGroupRoles(String token);

  /// Send an invitation to join a group.
  Future<void> sendInvitation({
    required String groupId,
    required String userId,
    required String roleWire,
    required String token,
  });
}
