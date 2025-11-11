// lib/c-frontend/utils/roles/group_role/group_role_icons.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';

extension GroupRoleIconX on GroupRole {
  IconData get icon => switch (this) {
        GroupRole.owner => Icons.workspace_premium_rounded,
        GroupRole.admin => Icons.admin_panel_settings_rounded,
        GroupRole.coAdmin => Icons.shield_rounded,
        GroupRole.member => Icons.person_rounded,
      };
}
