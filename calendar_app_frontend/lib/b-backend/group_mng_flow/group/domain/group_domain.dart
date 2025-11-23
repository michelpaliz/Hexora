// lib/b-backend/group_mng_flow/group/domain/group_domain.dart
import 'dart:async';
import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/group/group_business_hours.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';
import 'package:hexora/a-models/user_model/user.dart';
// UserDomain is referenced for refresh flow
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/resolver/event_group_resolver.dart';
// Repos (interfaces)
import 'package:hexora/b-backend/group_mng_flow/group/repository/i_group_repository.dart';

class GroupDomain extends ChangeNotifier {
  // Dependencies
  final IGroupRepository groupRepository; // repo owns group streams
  final IUserRepository userRepository; // interface, DI-provided
  final GroupEventResolver groupEventResolver;

  // Current user & group
  late User currentUser;
  Group? _currentGroup;
  Group? get currentGroup => _currentGroup;

  // ---- UI-facing state (no StreamControllers here) -------------------------
  final ValueNotifier<List<User>> usersInGroup = ValueNotifier<List<User>>([]);
  final ValueNotifier<Map<String, String>> userRoles =
      ValueNotifier<Map<String, String>>({});
  final ValueNotifier<Map<String, UserInviteStatus>?> invitationStatus =
      ValueNotifier<Map<String, UserInviteStatus>?>(null);

  bool _groupsInitialized = false;

  GroupDomain({
    required this.groupRepository,
    required this.userRepository, // <-- inject IUserRepository
    required this.groupEventResolver,
    required User? user,
  }) {
    if (user != null) setCurrentUser(user);
  }

  // ── Current user wiring ────────────────────────────────────────────────────
  void setCurrentUser(User? user) {
    if (user == null) return;
    currentUser = user;

    if (!_groupsInitialized) {
      _groupsInitialized = true;
      _initialRefreshForUser(currentUser);
    }
  }

  Future<void> _initialRefreshForUser(User user) async {
    try {
      await groupRepository.refreshUserGroupsByIds(user.id, user.groupIds);
    } catch (e) {
      devtools.log('❌ initial group refresh failed: $e');
    }
  }

  // ── Current group selection ────────────────────────────────────────────────
  set currentGroup(Group? group) {
    if (_currentGroup?.id == group?.id) return;
    _currentGroup = group;

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  // ── Repo-owned stream surface for UI ───────────────────────────────────────
  Stream<List<Group>> watchGroupsForUser(String userId) =>
      groupRepository.userGroups$(userId);

  /// Re-fetches the current user, then refreshes the repo stream from latest groupIds.
  Future<void> refreshGroupsForCurrentUser(UserDomain userDomain) async {
    final freshUser = await userDomain.getUser();
    if (freshUser != null) {
      userDomain.setCurrentUser(freshUser);
      await groupRepository.refreshUserGroupsByIds(
        freshUser.id,
        freshUser.groupIds,
      );
    }
  }

  /// Accept/decline invitation then refresh groups stream.
  Future<void> respondToInviteAndRefresh({
    required String groupId,
    required String userId,
    required bool accepted,
    required UserDomain userDomain,
  }) async {
    await groupRepository.respondToInvite(
      groupId: groupId,
      userId: userId,
      accepted: accepted,
    );
    await refreshGroupsForCurrentUser(userDomain);
  }

  // ── Metadata helpers (roles / invites) ------------------------------------
  Future<void> fetchAndPopulateUsersAndRoles(String groupId) async {
    try {
      final meta = await groupRepository.getGroupMembersMeta(groupId);
      final roles = Map<String, String>.from(meta['userRoles'] ?? {});
      userRoles.value = roles;
    } catch (e) {
      devtools.log('❌ fetchAndPopulateUsersAndRoles: $e');
    }
  }

  Future<void> fetchAndPopulateUsersInvitationStatus(String groupId) async {
    try {
      final meta = await groupRepository.getGroupMembersMeta(groupId);
      if (meta['invitedUsers'] != null) {
        final invitesMap =
            Map<String, dynamic>.from(meta['invitedUsers'] as Map);
        final invites = invitesMap.map(
          (k, v) => MapEntry(k, UserInviteStatus.fromJson(v)),
        );
        invitationStatus.value = invites;
      } else {
        invitationStatus.value = null;
      }
    } catch (e) {
      devtools.log('❌ fetchAndPopulateUsersInvitationStatus: $e');
    }
  }

  // ── Mutations that should trigger a repo refresh ───────────────────────────
  Future<bool> createGroup(Group group, UserDomain userDomain) async {
    try {
      await groupRepository.createGroup(group);
      await refreshGroupsForCurrentUser(userDomain);
      return true;
    } catch (e) {
      devtools.log('❌ Failed to create group: $e');
      return false;
    }
  }

  Future<Group> createGroupReturning(Group group, UserDomain userDomain) async {
    final created = await groupRepository.createGroup(group);
    await refreshGroupsForCurrentUser(userDomain);
    return created;
  }

  Future<bool> updateGroup(Group updatedGroup, UserDomain userDomain) async {
    try {
      await groupRepository.updateGroup(updatedGroup);
      await refreshGroupsForCurrentUser(userDomain);
      return true;
    } catch (e) {
      devtools.log('❌ Failed to update group: $e');
      return false;
    }
  }

  Future<bool> removeGroup(Group group, UserDomain userDomain) async {
    try {
      await groupRepository.deleteGroup(group.id);
      await refreshGroupsForCurrentUser(userDomain);
      return true;
    } catch (e) {
      devtools.log('❌ Failed to remove group: $e');
      return false;
    }
  }

  Future<Group?> setBusinessHours({
    required String groupId,
    required GroupBusinessHours hours,
  }) async {
    try {
      final updated = await groupRepository.setBusinessHours(groupId, hours);
      if (_currentGroup?.id == updated.id) {
        currentGroup = updated;
      }
      return updated;
    } catch (e) {
      devtools.log('❌ Failed to set business hours: $e');
      return null;
    }
  }

  Future<void> updateGroupPhoto({
    required String groupId,
    required String photoUrl,
    required String photoBlobName,
    required UserDomain userDomain,
  }) async {
    try {
      await refreshGroupsForCurrentUser(userDomain);
    } catch (e) {
      devtools.log('⚠️ updateGroupPhoto refresh failed: $e');
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    usersInGroup.dispose();
    userRoles.dispose();
    invitationStatus.dispose();
    super.dispose();
  }
}
