import 'package:hexora/a-models/user_model/user.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupSelectedUsersList extends StatelessWidget {
  final User currentUser;
  final List<User> usersInGroup;
  final Map<String, String> userRoles;
  final void Function(String username) onRemoveUser;
  final void Function(String username, String newRole) onRoleChanged;
  final List<String> availableRoles;
  final VoidCallback onConfirmChanges;

  const GroupSelectedUsersList({
    super.key,
    required this.currentUser,
    required this.usersInGroup,
    required this.userRoles,
    required this.onRemoveUser,
    required this.onRoleChanged,
    this.availableRoles = const ['Member', 'Co-Administrator'],
    required this.onConfirmChanges,
  });

  @override
  Widget build(BuildContext context) {
    // If there are no users in the group
    if (usersInGroup.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(AppLocalizations.of(context)!.noUsersInGroup),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display the users in the group
        ...usersInGroup.map((user) {
          final role = userRoles[user.userName] ?? 'Member';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    // Show "Administrator" for the current user
                    if (user.userName == currentUser.userName)
                      Text(
                        'Administrator',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    // Allow other users to change their role
                    if (user.userName != currentUser.userName)
                      _roleDropdown(
                        role,
                        (newRole) => onRoleChanged(user.userName, newRole),
                      ),
                    // Allow removal of users (except the current user)
                    if (user.userName != currentUser.userName)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () => onRemoveUser(user.userName),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),

        // Confirm changes button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Center(
            child: ElevatedButton(
              onPressed: onConfirmChanges,
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleDropdown(String currentRole, void Function(String) onChanged) {
    // Remove 'Administrator' for non-admin users
    final rolesToDisplay = List<String>.from(availableRoles);
    if (rolesToDisplay.contains('Administrator') &&
        currentUser.userName != currentRole) {
      rolesToDisplay.remove('Administrator');
    }

    return DropdownButton<String>(
      value: currentRole,
      items: rolesToDisplay.map((role) {
        return DropdownMenuItem<String>(value: role, child: Text(role));
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

extension on AppLocalizations {
  String get noUsersInGroup => "No users in group";
}
