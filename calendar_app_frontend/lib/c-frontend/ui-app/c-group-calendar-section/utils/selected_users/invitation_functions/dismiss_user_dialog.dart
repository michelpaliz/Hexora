import 'package:flutter/material.dart';

class DismissUserDialog extends StatelessWidget {
  final String userName;
  final bool isNewUser;
  final Function() onCancel;
  final Function() onConfirm;

  DismissUserDialog({
    required this.userName,
    required this.isNewUser,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isNewUser ? 'Confirm Removal' : 'Confirm Action'),
      content: Text(
        isNewUser
            ? 'You just added this user. Would you like to remove them from the invitation list?'
            : 'Are you sure you want to remove user $userName from the group?',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text('Confirm'),
        ),
      ],
    );
  }
}
