import 'package:hexora/a-models/notification_model/userInvitation_status.dart';

class InvitationMessageHelper {
  static String getInvitationMessage(UserInviteStatus? userInviteStatus) {
    if (userInviteStatus == null)
      return 'No invitation record found for this user.';

    if (userInviteStatus.invitationAnswer == null) {
      return 'The invitation is pending. No action is required yet.';
    } else if (userInviteStatus.invitationAnswer == false) {
      return getDeclinedMessage(userInviteStatus);
    } else if (userInviteStatus.invitationAnswer == true) {
      return 'The user accepted the invitation and is already in the group.';
    }

    return 'Unknown invitation status.';
  }

  static String getDeclinedMessage(UserInviteStatus userInviteStatus) {
    if (userInviteStatus.attempts == 1) {
      return 'The user declined the invitation. You can resend the invitation after 2 weeks.';
    } else if (userInviteStatus.attempts == 2) {
      return 'The user declined the invitation again. You can resend the invitation after 1 month.';
    } else if (userInviteStatus.attempts >= 3) {
      return 'The user has declined the invitation three times. No more attempts are allowed.';
    }
    return '';
  }
}
