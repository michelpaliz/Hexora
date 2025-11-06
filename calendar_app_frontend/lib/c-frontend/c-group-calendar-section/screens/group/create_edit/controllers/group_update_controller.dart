import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/domain/invite_domain.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupUpdateController {
  final BuildContext context;
  final Group originalGroup;
  final String groupName;
  final String groupDescription;
  final String imageUrl;
  final User currentUser;
  final Map<String, String> userRoles;
  final List<String> newlyInvitedUserIds;

  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final InvitationDomain invitationDomain; // ✅ injected

  GroupUpdateController({
    required this.context,
    required this.originalGroup,
    required this.groupName,
    required this.groupDescription,
    required this.imageUrl,
    required this.currentUser,
    required this.userRoles,
    required this.newlyInvitedUserIds,
    required this.userDomain,
    required this.groupDomain,
    required this.invitationDomain,
  });

  Future<bool> performGroupUpdate() async {
    if (groupName.trim().isEmpty || groupDescription.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.requiredTextFields);
      return false;
    }

    try {
      // 1) Update the group doc
      final updatedGroup = Group(
        id: originalGroup.id,
        name: groupName,
        ownerId: originalGroup.ownerId,
        userRoles: userRoles,
        userIds: originalGroup.userIds,
        createdTime: originalGroup.createdTime,
        description: groupDescription,
        photoUrl: imageUrl,
      );

      await groupDomain.updateGroup(updatedGroup, userDomain);

      // 2) Send invitations (server infers invitedBy from token)
      for (final invitedUserId in newlyInvitedUserIds) {
        await invitationDomain.sendInvitation(
          groupId: updatedGroup.id,
          userId: invitedUserId,
          role: userRoles[invitedUserId] ?? 'member',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.groupEdited)),
      );

      Navigator.pop(context);
      return true;
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      _showError(AppLocalizations.of(context)!.failedToEditGroup);
      return false;
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
