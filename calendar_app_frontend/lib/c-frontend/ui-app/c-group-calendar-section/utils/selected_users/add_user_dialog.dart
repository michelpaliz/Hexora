import 'package:hexora/a-models/user_model/user.dart';
import 'package:flutter/material.dart';

class AddUserDialog extends StatefulWidget {
  final User? currentUser;
  final bool? group;
  final Function(String) onAddUser;

  const AddUserDialog({
    required this.currentUser,
    required this.group,
    required this.onAddUser,
  });

  @override
  _AddUserDialogState createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter a username',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_usernameController.text.isNotEmpty) {
              widget.onAddUser(_usernameController.text);
              Navigator.of(context).pop(); // Close dialog
            }
          },
          child: Text('Add User'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
