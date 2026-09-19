import 'dart:developer' as devtools show log;

import 'package:flutter/foundation.dart';
import 'package:hexora/models/groups/invitations/invite.dart' show Invitation;
import 'package:hexora/services/groups/invite/repository/invite_repository.dart';

/// Supplies an auth token when the domain needs one (e.g. from AuthService()).
typedef TokenSupplier = Future<String?> Function();

/// Lightweight domain layer for invitations.
class InvitationDomain with ChangeNotifier {
  final InvitationRepository _repo;
  final TokenSupplier _tokenSupplier;

  InvitationDomain({
    required InvitationRepository repository,
    required TokenSupplier tokenSupplier,
  })  : _repo = repository,
        _tokenSupplier = tokenSupplier;

  // ---- minimal caches ----
  final Map<String, List<Invitation>> _byGroup = {}; // groupId -> invites
  List<Invitation>? _myInvites;

  List<Invitation>? cachedGroupInvitations(String groupId) => _byGroup[groupId];
  List<Invitation>? get cachedMyInvitations => _myInvites;

  Future<String> _requireToken() async {
    final t = await _tokenSupplier();
    if (t == null || t.isEmpty) {
      throw StateError('InvitationDomain: missing auth token');
    }
    return t;
  }

  // -----------------------------------------------------------------------------
  // Create / List
  // -----------------------------------------------------------------------------
  Future<Invitation?> sendInvitation({
    required String groupId,
    String? userId,
    String? email,
    String role = 'member', // member | co-admin | admin
    String? message,
  }) async {
    try {
      final token = await _requireToken();
      final res = await _repo.create(
        groupId: groupId,
        userId: userId,
        email: email,
        role: role,
        message: message,
        token: token,
      );
      if (res is RepoSuccess<Invitation>) {
        final cur = _byGroup[groupId] ?? const <Invitation>[];
        _byGroup[groupId] = [
          res.data,
          ...cur.where((i) => i.id != res.data.id)
        ];
        notifyListeners();
        return res.data;
      }
      if (res is RepoFailure<Invitation>) {
        devtools.log('❌ sendInvitation failure: ${res.error}');
      }
    } catch (e) {
      devtools.log('❌ sendInvitation error: $e');
    }
    return null;
  }

  Future<List<Invitation>> listGroupInvitations(
    String groupId, {
    bool force = false,
  }) async {
    if (!force && _byGroup[groupId] != null) return _byGroup[groupId]!;
    try {
      final token = await _requireToken();
      final res = await _repo.listGroupInvitations(groupId, token: token);
      if (res is RepoSuccess<List<Invitation>>) {
        _byGroup[groupId] = res.data;
        notifyListeners();
        return res.data;
      }
      if (res is RepoFailure<List<Invitation>>) {
        devtools.log('❌ listGroupInvitations failure: ${res.error}');
      }
    } catch (e) {
      devtools.log('❌ listGroupInvitations error: $e');
    }
    return _byGroup[groupId] ?? const <Invitation>[];
  }

  Future<List<Invitation>> listMyInvitations({
    String? userId,
    String? email,
    bool force = false,
  }) async {
    if (!force && _myInvites != null) return _myInvites!;
    try {
      final token = await _requireToken();
      final res = await _repo.listMyInvitations(
        token: token,
        userId: userId,
        email: email,
      );
      if (res is RepoSuccess<List<Invitation>>) {
        _myInvites = res.data;
        notifyListeners();
        return res.data;
      }
      if (res is RepoFailure<List<Invitation>>) {
        devtools.log('❌ listMyInvitations failure: ${res.error}');
      }
    } catch (e) {
      devtools.log('❌ listMyInvitations error: $e');
    }
    return _myInvites ?? const <Invitation>[];
  }

  // -----------------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------------
  Future<Invitation?> accept(String invitationId) async {
    try {
      final token = await _requireToken();
      final res = await _repo.accept(invitationId, token: token);
      if (res is RepoSuccess<Invitation>) {
        _patchCaches(res.data);
        return res.data;
      }
      if (res is RepoFailure<Invitation>) {
        devtools.log('❌ accept failure: ${res.error}');
      }
    } catch (e) {
      devtools.log('❌ accept error: $e');
    }
    return null;
  }

  Future<Invitation?> decline(String invitationId, {String? reason}) async {
    try {
      final token = await _requireToken();
      final res =
          await _repo.decline(invitationId, token: token, reason: reason);
      if (res is RepoSuccess<Invitation>) {
        _patchCaches(res.data);
        return res.data;
      }
      if (res is RepoFailure<Invitation>) {
        devtools.log('❌ decline failure: ${res.error}');
      }
    } catch (e) {
      devtools.log('❌ decline error: $e');
    }
    return null;
  }

  Future<Invitation?> resend(String invitationId) async {
    try {
      final token = await _requireToken();
      final res = await _repo.resend(invitationId, token: token);
      if (res is RepoSuccess<Invitation>) {
        _patchCaches(res.data);
        return res.data;
      }
      if (res is RepoFailure<Invitation>) {
        devtools.log('❌ resend failure: ${res.error}');
      }
    } catch (e) {
      devtools.log('❌ resend error: $e');
    }
    return null;
  }

  Future<Invitation?> revoke(String invitationId, {String? reason}) async {
    try {
      final token = await _requireToken();
      final res =
          await _repo.revoke(invitationId, token: token, reason: reason);
      if (res is RepoSuccess<Invitation>) {
        _patchCaches(res.data);
        return res.data;
      }
      if (res is RepoFailure<Invitation>) {
        devtools.log('❌ revoke failure: ${res.error}');
      }
    } catch (e) {
      devtools.log('❌ revoke error: $e');
    }
    return null;
  }

  // -----------------------------------------------------------------------------
  // Cache utilities
  // -----------------------------------------------------------------------------
  void _patchCaches(Invitation updated) {
    final g = updated.groupId;
    final list = _byGroup[g];
    if (list != null) {
      final idx = list.indexWhere((i) => i.id == updated.id);
      if (idx >= 0) {
        _byGroup[g] = [...list..[idx] = updated];
      } else {
        _byGroup[g] = [updated, ...list];
      }
    }
    if (_myInvites != null) {
      final idx = _myInvites!.indexWhere((i) => i.id == updated.id);
      if (idx >= 0) {
        _myInvites = [..._myInvites!..[idx] = updated];
      }
    }
    notifyListeners();
  }

  void invalidateGroup(String groupId) {
    _byGroup.remove(groupId);
    notifyListeners();
  }

  void invalidateMine() {
    _myInvites = null;
    notifyListeners();
  }
}
