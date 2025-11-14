import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';

class UserFilterService {
  static Map<String, UserInviteStatus> filterUsers(
    String currentUserRoleValue,
    User? currentUser,
    Map<String, UserInviteStatus> usersInvitations,
    bool showAccepted,
    bool showPending,
    bool showNotWantedToJoin,
  ) {
    final adminUserName = currentUserRoleValue == "Administrator"
        ? currentUser!.userName
        : null;

    final filteredEntries = usersInvitations.entries.where((entry) {
      final username = entry.key;
      final accepted = entry.value.invitationAnswer;

      if (username == adminUserName) return false;
      if (showAccepted && accepted == true) return true;
      if (showPending && accepted == null) return true;
      if (showNotWantedToJoin && accepted == false) return true;
      return false;
    }).toList();

    return Map.fromEntries(filteredEntries);
  }
}
