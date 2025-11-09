import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/c-frontend/utils/enums/group_role/group_role.dart';

class InviteMembersUseCase {
  final InvitationRepository invitations;
  final AuthProvider auth;
  InviteMembersUseCase(this.invitations, this.auth);

  Future<void> call({
    required String groupId,
    required List<User> members,
    required User owner,
    required Map<String, GroupRole> roles,
  }) async {
    final token = auth.lastToken;
    if (token == null) throw StateError('Not authenticated');

    for (final u in members) {
      if (u.id == owner.id) continue;
      final role = (roles[u.id] ?? GroupRole.member);
      final res = await invitations.create(
        groupId: groupId,
        userId: u.id,
        role: _toWire(role),
        token: token,
      );
      if (res is RepoFailure) {
        // devtools.log(
        //     '❌ Invite failed for ${u.userName} (${role.name}) -> ${res.runtimeType}');
      }
    }
  }

  String _toWire(GroupRole r) => r.wire;
}
