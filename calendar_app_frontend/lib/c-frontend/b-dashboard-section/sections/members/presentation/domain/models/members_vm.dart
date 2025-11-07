import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/Members_count.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/domain/models/members_ref.dart';

class MembersVM extends ChangeNotifier {
  MembersVM({
    required this.group,
    required this.groupDomain,
    required this.inviteRepo,
    required this.auth,
  });

  final Group group;
  final GroupDomain groupDomain;
  final InvitationRepository inviteRepo;
  final AuthProvider auth;

  MembersCount? _counts;
  bool _loadingCounts = false;

  List<Invitation> _invitations = const [];
  bool _loadingInvites = false;

  MembersCount? get counts => _counts;
  bool get isLoading => _loadingCounts || _loadingInvites;

  Future<void> refreshAll() async {
    await Future.wait([_loadCounts(), _loadInvites()]);
  }

  Future<void> _loadCounts() async {
    _loadingCounts = true;
    notifyListeners();
    try {
      _counts = await groupDomain.groupRepository
          .getMembersCount(group.id, mode: 'union');
    } finally {
      _loadingCounts = false;
      notifyListeners();
    }
  }

  Future<void> _loadInvites() async {
    _loadingInvites = true;
    notifyListeners();
    try {
      final token = auth.lastToken;
      if (token == null) return;
      final res = await inviteRepo.listGroupInvitations(group.id, token: token);
      if (res is RepoSuccess<List<Invitation>>) _invitations = res.data;
    } finally {
      _loadingInvites = false;
      notifyListeners();
    }
  }

  // ---- Mapping helpers ----
  List<MemberRef> get accepted {
    return group.userIds.map((id) {
      final role = group.userRoles[id] ?? 'member';
      return MemberRef(
        username: id,
        role: role,
        statusToken: 'Accepted',
        ownerId: group.ownerId,
      );
    }).toList();
  }

  List<MemberRef> get pending {
    return _invitations
        .where((i) => i.status == InvitationStatus.pending)
        .map(_invToRef('Pending'))
        .toList();
  }

  List<MemberRef> get notAccepted {
    return _invitations
        .where((i) =>
            i.status == InvitationStatus.declined ||
            i.status == InvitationStatus.revoked ||
            i.status == InvitationStatus.expired)
        .map(_invToRef('NotAccepted'))
        .toList();
  }

  int get totalAccepted => counts?.accepted ?? accepted.length;
  int get totalPending => counts?.pending ?? pending.length;
  int get totalNotAccepted => notAccepted.length;

  String Function(Invitation) _roleOf = (inv) {
    switch (inv.role) {
      case GroupRole.admin:
        return 'admin';
      case GroupRole.coAdmin:
        return 'co-admin';
      case GroupRole.member:
        return 'member';
    }
  };

  MemberRef Function(Invitation) _invToRef(String status) => (inv) {
        final display = inv.email ?? inv.userId ?? 'unknown';
        return MemberRef(
          username: display,
          role: _roleOf(inv),
          statusToken: status,
          ownerId: group.ownerId,
        );
      };
}
