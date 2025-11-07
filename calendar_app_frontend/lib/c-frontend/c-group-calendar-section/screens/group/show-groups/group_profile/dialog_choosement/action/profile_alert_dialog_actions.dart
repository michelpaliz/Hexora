import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/action/edit_group_arg.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../confirmation_dialog.dart';

List<Widget> buildProfileDialogActions(
  BuildContext context,
  Group group,
  User user,
  bool hasPermission,
  String role,
  UserDomain userDomain,
  GroupDomain groupDomain,
) {
  final loc = AppLocalizations.of(context)!;
  final roleDisplay = role[0].toUpperCase() + role.substring(1);
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  // ✅ body styles for consistent typography
  final bodyM = theme.textTheme.bodyMedium!;
  final bodyS = theme.textTheme.bodySmall!;

  const actionSpacing = SizedBox(height: 8);

  if (hasPermission) {
    return [
      // ✏️ Edit Button
      TextButton(
        onPressed: () async {
          Navigator.of(context).pop();
          await Future.delayed(const Duration(milliseconds: 100));

          final overlayContext =
              Navigator.of(context, rootNavigator: true).context;

          showDialog(
            context: overlayContext,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final selectedGroup =
                await groupDomain.groupRepository.getGroupById(group.id);
            final users = await userDomain.getUsersForGroup(selectedGroup);

            if (overlayContext.mounted) Navigator.of(overlayContext).pop();

            Navigator.pushNamed(
              overlayContext,
              AppRoutes.editGroupData,
              arguments: EditGroupArguments(
                group: selectedGroup,
                users: users,
              ),
            );
          } catch (e) {
            if (overlayContext.mounted) Navigator.of(overlayContext).pop();
            ScaffoldMessenger.of(overlayContext).showSnackBar(
              SnackBar(content: Text('${loc.failedToEditGroup} $e')),
            );
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit),
            const SizedBox(width: 8),
            Text(
              loc.editGroup,
              style: bodyM.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),

      actionSpacing,

      // 🗑️ Remove Group Button (destructive)
      TextButton(
        onPressed: () async {
          try {
            final overlayContext =
                Navigator.of(context, rootNavigator: true).context;

            showDialog(
              context: overlayContext,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            final freshGroup =
                await groupDomain.groupRepository.getGroupById(group.id);
            final members = await userDomain.getUsersForGroup(freshGroup);

            if (overlayContext.mounted) Navigator.of(overlayContext).pop();

            if (freshGroup.ownerId != user.id) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.permissionDeniedInf)),
                );
              }
              return;
            }

            final nonOwnerMembers =
                members.where((m) => m.id != freshGroup.ownerId).toList();

            if (nonOwnerMembers.isNotEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.removeMembersFirst)),
                );
              }
              return;
            }

            final confirm =
                await showConfirmationDialog(context, loc.questionDeleteGroup);
            if (!confirm) return;

            try {
              final ok = await groupDomain.removeGroup(freshGroup, userDomain);
              if (ok && context.mounted) Navigator.pop(context);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.failedToEditGroup)),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${loc.failedToEditGroup} $e')),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${loc.failedToEditGroup} $e')),
              );
            }
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: cs.errorContainer,
          foregroundColor: cs.onErrorContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_forever),
            const SizedBox(width: 8),
            Text(
              loc.remove,
              style: bodyM.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ];
  } else {
    return [
      // 🚫 Permission Denied Info
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: cs.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(
          loc.permissionDeniedRole(roleDisplay),
          style: bodyS.copyWith(fontWeight: FontWeight.w500),
        ),
      ),

      actionSpacing,

      // 🚪 Leave Group Button
      TextButton(
        onPressed: () async {
          final confirm = await showConfirmationDialog(
            context,
            loc.leaveGroupQuestion,
          );
          if (!confirm) return;

          try {
            await groupDomain.groupRepository.leaveGroup(user.id, group.id);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${loc.failedToEditGroup} $e')),
              );
            }
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: cs.errorContainer,
          foregroundColor: cs.onErrorContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout),
            const SizedBox(width: 8),
            Text(
              loc.leaveGroup,
              style: bodyM.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ];
  }
}
