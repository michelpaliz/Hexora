import 'package:hexora/models/notifications/user_invitation_status.dart';
import 'package:flutter/material.dart';

class RoleChangeDialogActions {
  static List<Widget> buildDialogActions(
    BuildContext context,
    String userName,
    String? selectedRole,
    Map<String, String> usersRoles,
    Map<String, UserInviteStatus> usersInvitations,
  ) {
    return [
      TextButton(
        onPressed: () {
          // ✅ Only update user's role
          if (selectedRole != null) {
            usersRoles[userName] = selectedRole;
          }
          Navigator.of(context).pop();
        },
        child: const Text('OK'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
    ];
  }
}
