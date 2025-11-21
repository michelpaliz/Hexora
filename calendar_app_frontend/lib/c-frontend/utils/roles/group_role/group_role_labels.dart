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

}

/// Convenience top-level helper
String roleLabelOf(BuildContext context, GroupRole role) =>
    role.label(AppLocalizations.of(context)!);
