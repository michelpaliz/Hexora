import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/utils/selected_users/invitation_functions/dismiss_user_dialog.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String userName;
  final User user;
  final String roleValue;
  final Function(String userName) onDismissed; // Logical removal
  final Function(String userName) onChangeRole;

  UserTile({
    required this.userName,
    required this.user,
    required this.roleValue,
    required this.onDismissed,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(userName),
      direction: roleValue.trim() != 'Administrator'
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (direction) async {
        bool? confirmDismissal = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return DismissUserDialog(
              userName: userName,
              isNewUser: false, // Update this based on your logic
              onCancel: () {
                Navigator.of(
                  dialogContext,
                ).pop(false); // Do not confirm dismissal
              },
              onConfirm: () {
                // Confirm dismissal but don't remove from state/UI
                Navigator.of(dialogContext).pop(true);
              },
            );
          },
        );

        // If dismissal is confirmed, we don't want the Dismissible widget to disappear.
        if (confirmDismissal == true) {
          // Call the logical removal (e.g., sending a request to the server)
          onDismissed(userName);
        }

        // Returning false prevents the widget from being dismissed in the UI
        return false;
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        title: Text(userName),
        subtitle: Text(roleValue),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
              ? NetworkImage(user.photoUrl!)
              : AssetImage('assets/images/default_profile.png')
                    as ImageProvider,
          // Default profile picture
        ),
        trailing: roleValue.trim() != 'Administrator'
            ? GestureDetector(
                onTap: () => onChangeRole(userName),
                child: Icon(Icons.settings, color: Colors.blue),
              )
            : SizedBox.shrink(),
        onTap: roleValue.trim() != 'Administrator'
            ? () => onChangeRole(userName)
            : null,
      ),
    );
  }
}
