// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/meta_pills.dart
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'pill.dart';

class MetaPills extends StatelessWidget {
  const MetaPills({
    super.key,
    required this.participants,
    required this.role,
  });

  final int participants;
  final String role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodySmall = Theme.of(context).textTheme.bodySmall!;

    final pillTextStyle = bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onPrimary,
    );

    final translatedRole = _tRole(context, role);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Pill(
          icon: Icons.person,
          label: '$participants',
          background: LinearGradient(
            colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
          ),
          textStyle: pillTextStyle,
        ),
        Pill(
          icon: Icons.verified_user,
          label: translatedRole,
          background: LinearGradient(
            colors: [scheme.secondary, scheme.secondary.withOpacity(0.7)],
          ),
          textStyle: pillTextStyle.copyWith(color: scheme.onSecondary),
          iconColor: scheme.onSecondary,
        ),
      ],
    );
  }
}

/// Map raw role → localized role using AppLocalizations.
/// Falls back to the original string if no key matches.
String _tRole(BuildContext context, String role) {
  final loc = AppLocalizations.of(context)!;

  final norm = role
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  switch (norm) {
    case 'owner':
      return loc.roleOwner; // ← add to ARB
    case 'administrator':
    case 'admin':
      return loc.roleAdministrator; // ← add to ARB
    case 'co administrator':
    case 'coadministrator':
    case 'co admin':
    case 'coadmin':
      return loc.roleCoAdministrator; // ← add to ARB
    case 'member':
      return loc.roleMember; // ← add to ARB
    case 'guest':
      return loc.roleGuest; // ← add to ARB
    default:
      return role; // graceful fallback
  }
}
