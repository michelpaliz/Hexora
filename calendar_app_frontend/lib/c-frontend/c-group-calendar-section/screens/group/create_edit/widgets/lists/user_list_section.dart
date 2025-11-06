import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/selected_users/invitation_functions/dismiss_user_dialog.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/group_user_card.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/edit_screen/functions/user/user_removal_service.dart';
import 'package:hexora/f-themes/shape/rounded/rounded_section_card.dart';
import 'package:hexora/l10n/app_localizations.dart';

class UserListSection extends StatelessWidget {
  final Map<String, User> newUsers;
  final Map<String, String> usersRoles;
  final Map<String, UserInviteStatus> usersInvitations;
  final Map<String, UserInviteStatus> usersInvitationAtFirst;
  final Group group;
  final List<User> usersInGroup;
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final NotificationDomain notificationDomain;
  final Function(String userName, String newRole) onChangeRole;
  final Function(String userName) onUserRemoved;
  final bool showPending;
  final bool showAccepted;
  final bool showNotWantedToJoin;
  final bool showNewUsers;
  final bool showExpired;

  const UserListSection({
    Key? key,
    required this.newUsers,
    required this.usersRoles,
    required this.usersInvitations,
    required this.usersInvitationAtFirst,
    required this.group,
    required this.usersInGroup,
    required this.userDomain,
    required this.groupDomain,
    required this.notificationDomain,
    required this.onChangeRole,
    required this.onUserRemoved,
    required this.showPending,
    required this.showAccepted,
    required this.showNotWantedToJoin,
    required this.showNewUsers,
    required this.showExpired,
  }) : super(key: key);

  bool _isDuplicate(String userName) {
    final isNew = newUsers.containsKey(userName);
    final isInGroup = usersInGroup.any((user) => user.userName == userName);
    final isInvited = usersInvitations.containsKey(userName);

    // Only hide if already a member and not invited
    final isDuplicate = (isInGroup && !isInvited);

    print(
      '🧪 _isDuplicate → $userName: '
      'isNew: $isNew, isInGroup: $isInGroup, isInvited: $isInvited, '
      '→ isDuplicate: $isDuplicate',
    );

    return isDuplicate;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    print('👥 usersInGroup: ${usersInGroup.map((u) => u.userName).toList()}');
    print('📩 invitedUsers: ${usersInvitations.keys.toList()}');

    final filteredInvitedUsers = usersInvitations.entries.where((entry) {
      final userName = entry.key;
      if (_isDuplicate(userName)) return false;

      final rawStatus = entry.value.informationStatus;
      final normalizedStatus =
          rawStatus.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

      final bool? answer = entry.value.invitationAnswer;

      final isAccepted = normalizedStatus == 'accepted' || answer == true;
      final isDeclined = normalizedStatus == 'notaccepted' ||
          normalizedStatus == 'declined' ||
          answer == false;
      final isExpired = normalizedStatus == 'expired';
      final isPending = normalizedStatus == 'pending' ||
          (answer == null && !isAccepted && !isDeclined && !isExpired);

      print('🔎 $userName → status="$rawStatus" (→ $normalizedStatus), '
          'answer=$answer → '
          'pending:$isPending accepted:$isAccepted declined:$isDeclined expired:$isExpired');

      if (isPending && showPending) return true;
      if (isAccepted && showAccepted) return true;
      if (isDeclined && showNotWantedToJoin) return true;
      if (isExpired && showExpired) return true;

      return false;
    }).toList();

    return RoundedSectionCard(
      title: loc.groupMembers, // 🔤 localized
      child: Column(
        children: [
          // 1) Newly added users
          if (showNewUsers)
            ...newUsers.entries.map((entry) {
              final userName = entry.key;
              final user = entry.value;
              final selectedRole = usersRoles[userName];

              return GroupUserCard(
                userName: userName,
                role: selectedRole ?? loc.member, // 🔤 localized fallback
                photoUrl: user.photoUrl,
                isAdmin: (selectedRole == 'Administrator' ||
                    selectedRole == loc.administrator),
                onRemove: () => _showDismissDialog(context, userName),
              );
            }).toList(),

          // 2) Invited users (filtered)
          if (filteredInvitedUsers.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                loc.noInvitedUsersToDisplay, // 🔤 localized empty state
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ] else ...[
            ...filteredInvitedUsers.map((entry) {
              final userName = entry.key;
              final inviteStatus = entry.value;

              print(
                  '📦 Rendering card: $userName → ${inviteStatus.informationStatus}');

              return GroupUserCard(
                userName: userName,
                role: inviteStatus.role,
                photoUrl: null,
                isAdmin: false,
                status: inviteStatus.informationStatus,
                sendingDate: inviteStatus.sendingDate,
                onRemove: null,
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  void _showDismissDialog(BuildContext context, String userName) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => DismissUserDialog(
        userName: userName,
        isNewUser: !usersInvitationAtFirst.containsKey(userName),
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () async {
          final removalService = UserRemovalService(
            context: context,
            usersInGroup: usersInGroup,
            usersInvitations: usersInvitations,
            usersRoles: usersRoles,
            groupDomain: groupDomain,
            userDomain: userDomain,
            group: group,
            notificationDomain: notificationDomain,
          );

          final bool? invitationStatus =
              usersInvitations[userName]?.invitationAnswer;

          final success = await removalService.performUserRemoval(
            userName,
            invitationStatus,
            usersInvitationAtFirst.containsKey(userName),
          );

          Navigator.of(ctx).pop();

          final snackBar = SnackBar(
            content: Text(
              success
                  ? loc.userRemovedSuccessfully(userName) // 🔤 localized
                  : loc.failedToRemoveUser(userName), // 🔤 localized
            ),
            duration: const Duration(seconds: 5),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          if (success) onUserRemoved(userName);
        },
      ),
    );
  }
}
