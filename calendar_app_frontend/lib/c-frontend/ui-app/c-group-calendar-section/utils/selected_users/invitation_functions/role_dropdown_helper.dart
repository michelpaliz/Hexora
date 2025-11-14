import 'package:hexora/a-models/notification_model/userInvitation_status.dart';

class RoleDropdownHelper {
  static bool shouldShowRoleDropdown(UserInviteStatus? userInviteStatus) {
    if (userInviteStatus == null) return false;

    final int daysSinceSent = DateTime.now()
        .difference(userInviteStatus.sendingDate)
        .inDays;

    if (userInviteStatus.invitationAnswer == false) {
      if (userInviteStatus.attempts == 1 && daysSinceSent >= 2) {
        return true;
      } else if (userInviteStatus.attempts == 2 && daysSinceSent >= 30) {
        return true;
      }
    } else if (userInviteStatus.invitationAnswer == true) {
      return true;
    }
    return false;
  }

  static String getAdditionalMessage(UserInviteStatus? userInviteStatus) {
    if (userInviteStatus == null) return '';

    final int daysSinceSent = DateTime.now()
        .difference(userInviteStatus.sendingDate)
        .inDays;

    if (userInviteStatus.invitationAnswer == false) {
      if (userInviteStatus.attempts == 1 && daysSinceSent >= 2) {
        return 'Time has passed. You can now change the role and resend the invitation.';
      } else if (userInviteStatus.attempts == 2 && daysSinceSent >= 30) {
        return 'Time has passed. You can now change the role and resend the invitation.';
      }
    }
    return '';
  }
}
