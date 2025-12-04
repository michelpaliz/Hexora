import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/l10n/app_localizations.dart';

String roleLabelOf(BuildContext context, GroupRole role) {
  final l = AppLocalizations.of(context)!;
  final key = _sanitize(role.wire);
  switch (key) {
    case 'owner':
      return l.roleOwner;
    case 'admin':
      return l.administrator;
    case 'coadmin':
      return l.coAdministrator;
    case 'member':
      return l.member;
    default:
      // Fallback: capitalized wire
      if (role.wire.isEmpty) return l.member;
      final w = role.wire;
      return w[0].toUpperCase() + w.substring(1);
  }
}

String _sanitize(String v) =>
    v.toLowerCase().replaceAll('-', '').replaceAll('_', '').trim();
