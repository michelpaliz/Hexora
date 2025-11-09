// lib/c-frontend/l10n/group_role_labels.dart
import 'package:flutter/widgets.dart';
import 'package:hexora/c-frontend/utils/enums/group_role/group_role.dart';
// Adjust this import to your generated l10n path:
import 'package:hexora/l10n/app_localizations.dart';

extension GroupRoleL10n on GroupRole {
  String label(AppLocalizations loc) => switch (this) {
        GroupRole.owner => loc.roleOwner, // fallback if needed
        GroupRole.admin => loc.administrator,
        GroupRole.coAdmin => loc.coAdministrator,
        GroupRole.member => loc.member,
      };
}

// Convenience helper if you prefer passing context:
extension GroupRoleL10nCtx on GroupRole {
  String labelOf(BuildContext context) =>
      (AppLocalizations.of(context)!).let((loc) => label(loc));
}

// tiny "let" helper if you like chaining; optional
extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
