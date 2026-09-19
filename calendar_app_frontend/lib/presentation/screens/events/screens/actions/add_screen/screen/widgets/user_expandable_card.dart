import 'package:hexora/models/user/user.dart';
import 'package:flutter/material.dart';

class UserExpandableCard extends StatefulWidget {
  final List<User> usersAvailable;
  final void Function(List<User>)? onSelectedUsersChanged;

  const UserExpandableCard({
    super.key,
    required this.usersAvailable,
    this.onSelectedUsersChanged,
  });

  @override
  State<UserExpandableCard> createState() => _UserExpandableCardState();
}

class _UserExpandableCardState extends State<UserExpandableCard> {
  final Set<User> _selectedUsers = {};

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("Select Participants"),
      children: widget.usersAvailable.map((user) {
        final isSelected = _selectedUsers.contains(user);
        return CheckboxListTile(
          title: Text(user.name),
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedUsers.add(user);
              } else {
                _selectedUsers.remove(user);
              }
              if (widget.onSelectedUsersChanged != null) {
                widget.onSelectedUsersChanged!(_selectedUsers.toList());
              }
            });
          },
        );
      }).toList(),
    );
  }
}
