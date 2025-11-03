import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/invited-user/group_role_extension.dart';

import 'alert_dialog/profile_alert_dialog_content.dart';
import 'profile_alert_dialog_actions.dart';

void showProfileAlertDialog(
  BuildContext context,
  Group group,
  User owner,
  User? currentUser,
  UserDomain userDomain,
  GroupDomain groupDomain,
  void Function(String?) updateRole, [
  bool? overridePermission,
]) {
  final user = currentUser ?? userDomain.user!;
  final role = group.getRoleForUser(user);
  final hasPermission = overridePermission ?? role != 'Member';
  updateRole(role);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54, // subtle dim
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      // The actual dialog UI (kept the same)
      return Center(
        child: Material(
          color: Colors.transparent,
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            content: ProfileDialogContent(group: group),
            actions: buildProfileDialogActions(
              context,
              group,
              user,
              hasPermission,
              role,
              userDomain,
              groupDomain,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from slightly below + fade
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08), // start a bit lower
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
