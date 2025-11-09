import 'package:flutter/widgets.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/l10n/app_localizations.dart';

extension GroupRoleL10n on GroupRole {
  String label(AppLocalizations loc) => switch (this) {
        GroupRole.owner => (loc.roleOwner ?? loc.administrator),
        GroupRole.admin => loc.administrator,
        GroupRole.coAdmin => loc.coAdministrator,
        GroupRole.member => loc.member,
      };
}

// Convenience top-level function (no extensions needed at callsite)
String roleLabelOf(BuildContext context, GroupRole role) =>
    role.label(AppLocalizations.of(context)!);
