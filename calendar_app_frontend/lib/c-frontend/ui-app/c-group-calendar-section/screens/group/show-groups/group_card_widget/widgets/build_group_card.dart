// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/build_group_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/invited-user/group_role_extension.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/profile_alert_dialog.dart';

import 'modern_group_card.dart';

/// Public entry used by GroupListSection. API unchanged.
Widget buildGroupCard(
  BuildContext context,
  Group group,
  User? currentUser,
  UserDomain userDomain,
  GroupDomain groupDomain,
  void Function(String?) updateRole,
) {
  final role =
      (currentUser != null) ? group.getRoleForUser(currentUser) : 'Member';
  final canEdit =
      role == 'Owner' || role == 'Administrator' || role == 'Co-Administrator';

  return StatefulBuilder(
    builder: (context, setState) {
      bool isHovered = false;
      bool isPressed = false;

      Future<void> _openProfile() async {
        try {
          final groupOwner =
              await userDomain.userRepository.getUserById(group.ownerId);
          // ignore: use_build_context_synchronously
          showProfileAlertDialog(
            context,
            group,
            groupOwner,
            currentUser,
            userDomain,
            groupDomain,
            updateRole,
            canEdit,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load group owner: $e')),
          );
        }
      }

      return MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() {
          isHovered = false;
          isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapCancel: () => setState(() => isPressed = false),
          onTapUp: (_) => setState(() => isPressed = false),
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: ModernGroupCard(
              group: group,
              role: role,
              isHovered: isHovered,
              onTap: _openProfile,
            ),
          ),
        ),
      );
    },
  );
}
