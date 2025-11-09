import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/c-frontend/k-enums/invitation/invitation_status.dart';

enum InvitationListType { group, me }

enum ViewStatus { idle, loading, refreshing, error }

class InvitationViewModel extends ChangeNotifier {
  final InvitationRepository _repo;
  final String _token;
  InvitationViewModel(this._repo, {required String token}) : _token = token;

  ViewStatus status = ViewStatus.idle;
  String? errorMessage;
  List<Invitation> invitations = const [];

  String? _currentGroupId;
  InvitationListType? _mode;

  Future<void> loadGroupInvitations(String groupId) async {
    _mode = InvitationListType.group;
    _currentGroupId = groupId;
    status = ViewStatus.loading;
    errorMessage = null;
    notifyListeners();
    final res = await _repo.listGroupInvitations(groupId, token: _token);
    switch (res) {
      case RepoSuccess<List<Invitation>>(:final data):
        invitations = data;
        status = ViewStatus.idle;
      case RepoFailure<List<Invitation>>(:final error):
        errorMessage = error.toString();
        status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMyInvitations({String? userId, String? email}) async {
    _mode = InvitationListType.me;
    _currentGroupId = null;
    status = ViewStatus.loading;
    errorMessage = null;
    notifyListeners();
    final res = await _repo.listMyInvitations(
        token: _token, userId: userId, email: email);
    switch (res) {
      case RepoSuccess<List<Invitation>>(:final data):
        invitations = data;
        status = ViewStatus.idle;
      case RepoFailure<List<Invitation>>(:final error):
        errorMessage = error.toString();
        status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_mode == InvitationListType.group && _currentGroupId != null) {
      status = ViewStatus.refreshing;
      notifyListeners();
      final res =
          await _repo.listGroupInvitations(_currentGroupId!, token: _token);
      switch (res) {
        case RepoSuccess<List<Invitation>>(:final data):
          invitations = data;
          status = ViewStatus.idle;
        case RepoFailure<List<Invitation>>(:final error):
          errorMessage = error.toString();
          status = ViewStatus.error;
      }
      notifyListeners();
    } else if (_mode == InvitationListType.me) {
      await loadMyInvitations();
    }
  }

  Future<void> accept(String invitationId) async {
    final idx = invitations.indexWhere((i) => i.id == invitationId);
    Invitation? backup = idx >= 0 ? invitations[idx] : null;
    if (idx >= 0) {
      invitations = List.of(invitations)
        ..[idx] = invitations[idx].copyWith(status: InvitationStatus.accepted);
      notifyListeners();
    }
    final res = await _repo.accept(invitationId, token: _token);
    switch (res) {
      case RepoSuccess<Invitation>(:final data):
        if (idx >= 0) {
          invitations = List.of(invitations)..[idx] = data;
          notifyListeners();
        }
      case RepoFailure<Invitation>():
        if (backup != null && idx >= 0) {
          invitations = List.of(invitations)..[idx] = backup;
          notifyListeners();
        }
    }
  }

  Future<void> decline(String invitationId, {String? reason}) async {
    final idx = invitations.indexWhere((i) => i.id == invitationId);
    Invitation? backup = idx >= 0 ? invitations[idx] : null;
    if (idx >= 0) {
      invitations = List.of(invitations)
        ..[idx] = invitations[idx].copyWith(status: InvitationStatus.declined);
      notifyListeners();
    }
    final res =
        await _repo.decline(invitationId, token: _token, reason: reason);
    switch (res) {
      case RepoSuccess<Invitation>(:final data):
        if (idx >= 0) {
          invitations = List.of(invitations)..[idx] = data;
          notifyListeners();
        }
      case RepoFailure<Invitation>():
        if (backup != null && idx >= 0) {
          invitations = List.of(invitations)..[idx] = backup;
          notifyListeners();
        }
    }
  }

  Future<void> resend(String invitationId) async {
    final res = await _repo.resend(invitationId, token: _token);
    if (res is RepoSuccess<Invitation>) {
      await refresh();
    }
  }

  Future<void> revoke(String invitationId, {String? reason}) async {
    final idx = invitations.indexWhere((i) => i.id == invitationId);
    Invitation? backup = idx >= 0 ? invitations[idx] : null;
    if (idx >= 0) {
      invitations = List.of(invitations)
        ..[idx] = invitations[idx].copyWith(status: InvitationStatus.revoked);
      notifyListeners();
    }
    final res = await _repo.revoke(invitationId, token: _token, reason: reason);
    switch (res) {
      case RepoSuccess<Invitation>(:final data):
        if (idx >= 0) {
          invitations = List.of(invitations)..[idx] = data;
          notifyListeners();
        }
      case RepoFailure<Invitation>():
        if (backup != null && idx >= 0) {
          invitations = List.of(invitations)..[idx] = backup;
          notifyListeners();
        }
    }
  }
}
