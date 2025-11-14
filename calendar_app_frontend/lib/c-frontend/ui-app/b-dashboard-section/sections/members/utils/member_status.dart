// c-frontend/b-calendar-section/screens/group-screen/members/utils/member_status.dart
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';

String statusFor(
  String username,
  UserInviteStatus? inv,
  Set<String> acceptedSet,
) {
  if (acceptedSet.contains(username)) return 'Accepted';

  final raw = (inv == null) ? '' : _extractInviteStatus(inv).toLowerCase();

  if (raw == 'accepted') return 'Accepted';
  if (raw == 'pending') return 'Pending';

  const notAcceptedTokens = [
    'rejected',
    'declined',
    'notaccepted',
    'not_accepted',
    'notwantedtojoin',
    'not_wanted_to_join',
    'cancelled',
  ];
  if (notAcceptedTokens.contains(raw)) return 'NotAccepted';
  if (inv != null) return 'Pending';
  return 'NotAccepted';
}

String _extractInviteStatus(UserInviteStatus inv) {
  try {
    final m = inv.toJson();
    for (final k in const ['status', 'state', 'inviteStatus', 'invitationStatus']) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
  } catch (_) {}
  return '';
}
