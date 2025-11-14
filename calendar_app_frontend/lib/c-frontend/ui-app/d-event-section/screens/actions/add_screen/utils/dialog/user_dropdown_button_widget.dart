import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/l10n/app_localizations.dart'; // ⬅️
import 'package:flutter/material.dart';

import 'dialog_button_widget.dart';

class UserDropdownTrigger extends StatefulWidget {
  final List<User> usersAvailable;
  const UserDropdownTrigger({Key? key, required this.usersAvailable})
      : super(key: key);

  @override
  _UserDropdownTriggerState createState() => _UserDropdownTriggerState();
}

class _UserDropdownTriggerState extends State<UserDropdownTrigger> {
  List<User> _selectedUsers = [];
  bool _isUserSelectionVisible = false;

  void _toggleUserSelection() =>
      setState(() => _isUserSelectionVisible = !_isUserSelectionVisible);

  void _updateSelectedUsers(List<User> selected) =>
      setState(() => _selectedUsers = selected);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // ⬅️

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _toggleUserSelection,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.userDropdownSelect), // ⬅️
              Icon(_isUserSelectionVisible
                  ? Icons.arrow_drop_up
                  : Icons.arrow_drop_down),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_isUserSelectionVisible)
          DialogButtonWidget(
            selectedUsers: _selectedUsers,
            usersAvailable: widget.usersAvailable,
            onUsersSelected: _updateSelectedUsers,
          ),
      ],
    );
  }
}
