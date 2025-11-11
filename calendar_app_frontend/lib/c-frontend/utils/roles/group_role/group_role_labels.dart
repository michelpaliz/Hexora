import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/l10n/app_localizations.dart';

extension GroupRoleL10n on GroupRole {
  String label(AppLocalizations l) => switch (this) {
        GroupRole.owner => l.roleOwner, // usually non-null
        GroupRole.admin => l.administrator,
        GroupRole.coAdmin => l.coAdministrator,
        GroupRole.member => l.member,
      };

  IconData get icon => switch (this) {
        GroupRole.owner => Icons.workspace_premium_rounded,
        GroupRole.admin => Icons.admin_panel_settings_rounded,
        GroupRole.coAdmin => Icons.shield_rounded,
        GroupRole.member => Icons.person_rounded,
      };
}

/// Convenience top-level helper
String roleLabelOf(BuildContext context, GroupRole role) =>
    role.label(AppLocalizations.of(context)!);
