// utils/members_derivation.dart
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';

String norm(dynamic v) => v?.toString().toLowerCase().trim() ?? '';

bool inviteIsAccepted(UserInviteStatus? inv) {
  if (inv == null) return false;
  final status = (inv.informationStatus).toLowerCase();
  return inv.invitationAnswer == true || status == 'accepted';
}

/// Returns (acceptedKeys, pendingInvitesMap<String, UserInviteStatus>)
({Set<String> accepted, Map<String, UserInviteStatus> pending})
    deriveAcceptedAndPending({
  required Iterable<dynamic>? userIds,
  required Map<String, UserInviteStatus>? invitedUsers,
}) {
  final accepted = (userIds ?? const <dynamic>[])
      .map(norm)
      .where((s) => s.isNotEmpty)
      .toSet();

  final invited = invitedUsers ?? const <String, UserInviteStatus>{};
  final invitedByUser = <String, UserInviteStatus>{
    for (final e in invited.entries) norm(e.key): e.value,
  };

  final pending = <String, UserInviteStatus>{
    for (final e in invitedByUser.entries)
      if (!inviteIsAccepted(e.value) && !accepted.contains(e.key))
        e.key: e.value,
  };

  return (accepted: accepted, pending: pending);
}
