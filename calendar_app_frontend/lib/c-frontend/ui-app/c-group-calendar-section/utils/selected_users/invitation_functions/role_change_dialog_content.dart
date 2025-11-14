import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/utils/selected_users/invitation_functions/invitation_message_helper.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/utils/selected_users/invitation_functions/role_dropdown_helper.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';

class RoleChangeDialogContent extends StatelessWidget {
  final String userName;
  final String? selectedRole;
  final UserInviteStatus? userInviteStatus;
  final Function(String?) onRoleSelected;

  RoleChangeDialogContent({
    required this.userName,
    required this.selectedRole,
    required this.userInviteStatus,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    String informativeMessage = InvitationMessageHelper.getInvitationMessage(
      userInviteStatus,
    );
    bool showRoleDropdown = RoleDropdownHelper.shouldShowRoleDropdown(
      userInviteStatus,
    );
    String additionalMessage = RoleDropdownHelper.getAdditionalMessage(
      userInviteStatus,
    );

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userInviteStatus != null)
              ListTile(
                title: Text("Invitation Status: ${userInviteStatus!.status}"),
                subtitle: Text(informativeMessage),
              ),
            if (additionalMessage.isNotEmpty) Text(additionalMessage),
            SizedBox(height: 20),
            if (showRoleDropdown)
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['Co-Administrator', 'Member'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newRole) {
                  setState(() {
                    onRoleSelected(newRole);
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        );
      },
    );
  }
}
