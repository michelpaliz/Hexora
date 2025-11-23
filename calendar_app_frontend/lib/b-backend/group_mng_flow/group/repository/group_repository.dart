import 'dart:async';
import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'dart:io';

import 'package:hexora/a-models/group_model/calendar/calendar.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/group/group_business_hours.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/group_mng_flow/group/api/i_group_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/group/repository/i_group_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:http/http.dart' as http;

/// Concrete repository with in-memory cache + per-user streams.
/// Depends on an abstract API client and a token supplier.
class GroupRepository implements IGroupRepository {
  GroupRepository({
    required IGroupApiClient apiClient,
    required TokenSupplier tokenSupplier,
  })  : _api = apiClient,
        _token = tokenSupplier;

  final IGroupApiClient _api;
  final TokenSupplier _token;

  // ── In-memory cache + streams (per user) ───────────────────────────────────
  final Map<String, List<Group>> _cacheByUserId = <String, List<Group>>{};
  final Map<String, StreamController<List<Group>>> _controllers =
      <String, StreamController<List<Group>>>{};

  StreamController<List<Group>> _getOrCreateController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<List<Group>>.broadcast(),
    );
  }

  @override
  Stream<List<Group>> userGroups$(String userId) {
    final ctrl = _getOrCreateController(userId);

    // Emit current cache snapshot for new listeners (if any).
    scheduleMicrotask(() {
      final snapshot = _cacheByUserId[userId];
      if (snapshot != null && !ctrl.isClosed) {
        ctrl.add(List<Group>.from(snapshot));
      }
    });

    return ctrl.stream;
  }

// bool _sameGroupSet(List<Group> a, List<Group> b) {
//   if (a.length != b.length) return false;

//   final byIdA = {for (final g in a) g.id: g};
//   final byIdB = {for (final g in b) g.id: g};

//   if (!byIdA.keys.toSet().containsAll(byIdB.keys)) return false;

//   // compare some fields that matter visually
//   for (final id in byIdA.keys) {
//     final ga = byIdA[id]!;
//     final gb = byIdB[id]!;

//     if (ga.name != gb.name ||
//         ga.description != gb.description ||
//         ga.photoUrl != gb.photoUrl) {
//       return false; // something changed
//     }
//   }
//   return true; // identical for our UI purposes
// }

// void _emitIfChanged(String userId, List<Group> next) {
//   final prev = _cacheByUserId[userId] ?? const <Group>[];
//   if (_sameGroupSet(prev, next)) return;
//   _cacheByUserId[userId] = next;
//   final ctrl = _getOrCreateController(userId);
//   if (!ctrl.isClosed) ctrl.add(List<Group>.from(next));
// }

  void _emitIfChanged(String userId, List<Group> next) {
    _cacheByUserId[userId] = next;
    final ctrl = _getOrCreateController(userId);
    if (!ctrl.isClosed) {
      ctrl.add(List<Group>.from(next));
    }
  }

  /// Refresh the per-user stream from a known list of group IDs.
  @override
  Future<void> refreshUserGroupsByIds(
    String userId,
    List<String> groupIds,
  ) async {
    final token = await _token();

    final uniqueIds = groupIds.toSet().toList();
    final results = await Future.wait(uniqueIds.map((id) async {
      try {
        final g = await _api.getGroupById(id, token);
        return g;
      } catch (_) {
        // If an id is 404 or fails, skip silently.
        return null;
      }
    }));

    final groups = results.whereType<Group>().toList();
    _emitIfChanged(userId, groups);
  }

  // ── CRUD + queries ─────────────────────────────────────────────────────────
  @override
  Future<Group> createGroup(Group group) async =>
      _api.createGroup(group, await _token());

  @override
  Future<Group> getGroupById(String groupId) async =>
      _api.getGroupById(groupId, await _token());

  @override
  Future<void> updateGroup(Group group) async {
    final ok = await _api.updateGroup(group, await _token());
    if (!ok) throw Exception('Failed to update group');
  }

  @override
  Future<void> deleteGroup(String groupId) async =>
      _api.deleteGroup(groupId, await _token());

  @override
  Future<List<Group>> getGroupsByUser(String userName) async =>
      _api.getGroupsByUser(userName, await _token());

  @override
  Future<void> leaveGroup(String userId, String groupId) async =>
      _api.leaveGroup(userId, groupId, await _token());

  @override
  Future<void> respondToInvite({
    required String groupId,
    required String userId,
    required bool accepted,
  }) async {
    await _api.respondToInvite(
      groupId: groupId,
      userId: userId,
      accepted: accepted,
      token: await _token(),
    );
    // Let your Domain re-fetch the user and call refreshUserGroupsByIds(...)
  }

  @override
  Future<MembersCount> getMembersCount(String groupId, {String? mode}) async =>
      _api.getMembersCount(groupId, await _token(), mode: mode);

  @override
  Future<Map<String, dynamic>> getGroupMembersMeta(String groupId) async =>
      _api.getGroupMembersMeta(groupId, await _token());

  @override
  Future<List<User>> getGroupMemberProfiles(
    String groupId, {
    List<String>? ids,
  }) async {
    final profiles =
        await _api.getGroupMemberProfiles(groupId, await _token(), ids: ids);
    return profiles.map((p) => User.fromJson(p)).toList();
  }

  @override
  Future<Calendar> getCalendarById(String calendarId) async =>
      _api.getCalendarById(calendarId, await _token());

  @override
  Future<Group> setBusinessHours(
    String groupId,
    GroupBusinessHours hours,
  ) async {
    final updated =
        await _api.setBusinessHours(groupId, hours, await _token());
    _replaceGroupInCache(updated);
    return updated;
  }

  // ── Media ──────────────────────────────────────────────────────────────────
  @override
  Future<void> uploadAndCommitGroupPhoto({
    required String groupId,
    required File file,
  }) async {
    final token = await _token();

    // Step 1: Upload to Azure Blob
    final uploadResult = await uploadImageToAzure(
      scope: 'groups',
      resourceId: groupId,
      file: file,
      accessToken: token,
    );

    // Step 2: Commit blob reference in backend
    final resp = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/groups/$groupId/photo'),
      headers: {
        'Authorization': 'Bearer token', // NOTE: auth header
        'Content-Type': 'application/json',
      }..update('Authorization', (_) => 'Bearer $token'),
      body: jsonEncode({'blobName': uploadResult.blobName}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to commit photo: ${resp.reasonPhrase}');
    }

    devtools.log('✅ Group photo updated for $groupId');
  }

  void _replaceGroupInCache(Group updated) {
    final entries = _cacheByUserId.entries.toList();
    for (final entry in entries) {
      final idx = entry.value.indexWhere((g) => g.id == updated.id);
      if (idx == -1) continue;

      final copy = List<Group>.from(entry.value);
      copy[idx] = updated;
      _cacheByUserId[entry.key] = copy;

      final controller = _controllers[entry.key];
      if (controller != null && !controller.isClosed) {
        controller.add(List<Group>.from(copy));
      }
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    for (final c in _controllers.values) {
      if (!c.isClosed) c.close();
    }
    _controllers.clear();
    _cacheByUserId.clear();
  }
}
