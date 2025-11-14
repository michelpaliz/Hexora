import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';

class UserList extends StatelessWidget {
  final Map<String, UserInviteStatus> filteredUsers; // key: userId
  final Map<String, String?> usersRoles; // key: userId
  final UserDomain userDomain;
  final Widget Function(String /*displayKey*/, User user, String role)
      buildUserTile;

  const UserList({
    super.key,
    required this.filteredUsers,
    required this.usersRoles,
    required this.userDomain,
    required this.buildUserTile,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredUsers.isEmpty) {
      return const Text("No user roles available");
    }

    return Column(
      children: filteredUsers.entries.map((entry) {
        final String userId = entry.key; // <-- now ID
        final UserInviteStatus invite = entry.value;

        return FutureBuilder<User>(
          // Prefer repository so the token is handled automatically
          future: userDomain.userRepository.getUserById(userId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (snap.hasError) {
              return ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(userId),
                subtitle: Text('Error: ${snap.error}'),
              );
            }
            if (!snap.hasData) {
              return ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: Text(userId),
                subtitle: const Text('User not found'),
              );
            }

            final user = snap.data!;
            // roles now expected to be keyed by userId, fallback to the invite’s role
            final roleValue = (usersRoles[userId] ?? invite.role);

            // Keep the existing buildUserTile signature:
            // If your tile expects username as the first arg, pass user.userName.
            return buildUserTile(user.userName, user, roleValue);
          },
        );
      }).toList(),
    );
  }
}
