import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/l10n/app_localizations.dart'; // ⬅️ add
import 'package:flutter/material.dart';

class DialogButtonWidget extends StatefulWidget {
  final List<User> selectedUsers;
  final List<User> usersAvailable;
  final void Function(List<User>) onUsersSelected;

  const DialogButtonWidget({
    Key? key,
    required this.selectedUsers,
    required this.usersAvailable,
    required this.onUsersSelected,
  }) : super(key: key);

  @override
  _DialogButtonWidgetState createState() => _DialogButtonWidgetState();
}

class _DialogButtonWidgetState extends State<DialogButtonWidget> {
  late List<User> _selectedUsers;

  @override
  void initState() {
    super.initState();
    _selectedUsers = List.from(widget.selectedUsers);
  }

  void _showUserSelectionDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // ⬅️

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.dialogSelectUsersTitle), // ⬅️
              content: SizedBox(
                width: 300,
                height: 150,
                child: _buildUserSelection(context, setState),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onUsersSelected(_selectedUsers);
                  },
                  child: Text(loc.dialogClose), // ⬅️
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserSelection(BuildContext context, StateSetter setState) {
    return ListView.builder(
      itemCount: widget.usersAvailable.length,
      itemBuilder: (context, index) {
        final user = widget.usersAvailable[index];
        final isSelected = _selectedUsers.contains(user);

        return CheckboxListTile(
          title: Text(user.userName),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedUsers.add(user);
              } else {
                _selectedUsers.remove(user);
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // ⬅️
    return Center(
      child: ElevatedButton(
        onPressed: () => _showUserSelectionDialog(context),
        child: Text(loc.dialogShowUsers), // ⬅️
      ),
    );
  }
}
