import 'package:hexora/models/groups/invitations/invite.dart';
import 'package:hexora/services/groups/invite/api/invite_api_client.dart';

sealed class RepoResult<T> {
  const RepoResult();
}
class RepoSuccess<T> extends RepoResult<T> { final T data; const RepoSuccess(this.data); }
class RepoFailure<T> extends RepoResult<T> { final Object error; final StackTrace? stackTrace; const RepoFailure(this.error,[this.stackTrace]); }

abstract class InvitationRepository {
  Future<RepoResult<Invitation>> create({required String groupId, String? email, String? userId, String? role, String? message, required String token, Map<String, dynamic>? extra});
  Future<RepoResult<List<Invitation>>> listGroupInvitations(String groupId, {required String token});
  Future<RepoResult<List<Invitation>>> listMyInvitations({required String token, String? userId, String? email});
  Future<RepoResult<Invitation>> accept(String invitationId, {required String token, String? note});
  Future<RepoResult<Invitation>> decline(String invitationId, {required String token, String? reason});
  Future<RepoResult<Invitation>> resend(String invitationId, {required String token});
  Future<RepoResult<Invitation>> revoke(String invitationId, {required String token, String? reason});
}

class HttpInvitationRepository implements InvitationRepository {
  final InvitationApiClient _api;
  HttpInvitationRepository(this._api);

  @override
  Future<RepoResult<Invitation>> create({required String groupId, String? email, String? userId, String? role, String? message, required String token, Map<String, dynamic>? extra}) async {
    try {
      final data = await _api.create(groupId: groupId, email: email, userId: userId, role: role, message: message, token: token, extra: extra);
      return RepoSuccess(data);
    } catch (e, st) { return RepoFailure(e, st); }
  }

  @override
  Future<RepoResult<List<Invitation>>> listGroupInvitations(String groupId, {required String token}) async {
    try { return RepoSuccess(await _api.listGroupInvitations(groupId, token: token)); }
    catch (e, st) { return RepoFailure(e, st); }
  }

  @override
  Future<RepoResult<List<Invitation>>> listMyInvitations({required String token, String? userId, String? email}) async {
    try { return RepoSuccess(await _api.listMyInvitations(token: token, userId: userId, email: email)); }
    catch (e, st) { return RepoFailure(e, st); }
  }

  @override
  Future<RepoResult<Invitation>> accept(String invitationId, {required String token, String? note}) async {
    try { return RepoSuccess(await _api.accept(invitationId, token: token, note: note)); }
    catch (e, st) { return RepoFailure(e, st); }
  }

  @override
  Future<RepoResult<Invitation>> decline(String invitationId, {required String token, String? reason}) async {
    try { return RepoSuccess(await _api.decline(invitationId, token: token, reason: reason)); }
    catch (e, st) { return RepoFailure(e, st); }
  }

  @override
  Future<RepoResult<Invitation>> resend(String invitationId, {required String token}) async {
    try { return RepoSuccess(await _api.resend(invitationId, token: token)); }
    catch (e, st) { return RepoFailure(e, st); }
  }

  @override
  Future<RepoResult<Invitation>> revoke(String invitationId, {required String token, String? reason}) async {
    try { return RepoSuccess(await _api.revoke(invitationId, token: token, reason: reason)); }
    catch (e, st) { return RepoFailure(e, st); }
  }
}

