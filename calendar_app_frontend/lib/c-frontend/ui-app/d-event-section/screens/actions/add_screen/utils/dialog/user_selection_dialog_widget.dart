import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/l10n/app_localizations.dart'; // ⬅️ Add this
import 'package:flutter/material.dart';

class UserSelectionDialog extends StatefulWidget {
  final List<User> selectedUsers;
  final List<User> usersAvailable;

  const UserSelectionDialog({
    Key? key,
    required this.selectedUsers,
    required this.usersAvailable,
  }) : super(key: key);

  @override
  _UserSelectionDialogState createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  late List<User> tempSelectedUsers;

  @override
  void initState() {
    super.initState();
    tempSelectedUsers = List.from(widget.selectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // ⬅️ Use localizations

    return AlertDialog(
      title: Text(loc.dialogSelectUsersTitle), // ⬅️ Localized title
      content: SizedBox(
        width: 300,
        height: 100,
        child: _buildUserSelection(context),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(tempSelectedUsers);
          },
          child: Text(loc.dialogClose), // ⬅️ Localized close
        ),
      ],
    );
  }

  Widget _buildUserSelection(BuildContext context) {
    return ListView.builder(
      itemCount: widget.usersAvailable.length,
      itemBuilder: (context, index) {
        final user = widget.usersAvailable[index];
        final isSelected = tempSelectedUsers.contains(user);

        return CheckboxListTile(
          title: Text(user.userName),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                tempSelectedUsers.add(user);
              } else {
                tempSelectedUsers.remove(user);
              }
            });
          },
        );
      },
    );
  }
}
