import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';

class UserRemovalService {
  final BuildContext context;
  final List<User> usersInGroup;
  final Map<String, UserInviteStatus> usersInvitations;
  final Map<String, String> usersRoles;
  final GroupDomain groupDomain;
  final UserDomain userDomain;
  final NotificationDomain notificationDomain;
  final Group group;

  UserRemovalService({
    required this.context,
    required this.usersInGroup,
    required this.usersInvitations,
    required this.usersRoles,
    required this.groupDomain,
    required this.userDomain,
    required this.notificationDomain,
    required this.group,
  });

  Future<bool> performUserRemoval(
    String fetchedUserName,
    bool? invitationStatus,
    bool isNewUser,
  ) async {
    try {
      final fetchedUser = usersInGroup.firstWhere(
        (user) => user.userName.toLowerCase() == fetchedUserName.toLowerCase(),
        orElse: () => throw Exception("User not found"),
      );

      if (isNewUser) {
        _handleNewUserRemoval(fetchedUser.userName);
        return true;
      } else {
        return await _handleExistingUserRemoval(fetchedUser, invitationStatus);
      }
    } catch (e) {
      debugPrint("Error removing user: $e");
      return false;
    }
  }

  void _handleNewUserRemoval(String fetchedUserName) {
    usersInGroup.removeWhere(
      (user) => user.userName.toLowerCase() == fetchedUserName.toLowerCase(),
    );
    usersInvitations.remove(fetchedUserName);
    usersRoles.remove(fetchedUserName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User removed before sending any invitation.'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<bool> _handleExistingUserRemoval(
    User fetchedUser,
    bool? invitationStatus,
  ) async {
    // Pending invite cannot be removed yet
    if (invitationStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${fetchedUser.userName} has a pending invitation and cannot be removed until it is answered.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }

    // Declined: keep record, nothing to remove
    if (invitationStatus == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${fetchedUser.userName} declined the invitation. Record retained.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return true;
    }

    try {
      // ✅ Use repository (throws on failure)
      await groupDomain.groupRepository.leaveGroup(
        fetchedUser.id,
        group.id,
      );

      // ✅ Refresh group via repository
      final updatedGroup =
          await groupDomain.groupRepository.getGroupById(group.id);
      groupDomain.currentGroup = updatedGroup;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${fetchedUser.userName} removed from the group.'),
          duration: const Duration(seconds: 5),
        ),
      );
      return true;
    } catch (e) {
      debugPrint("❌ Exception removing user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove user ${fetchedUser.userName} from the server.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }
  }
}
