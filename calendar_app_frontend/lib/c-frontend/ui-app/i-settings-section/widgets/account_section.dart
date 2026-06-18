// lib/c-frontend/i-settings-section/widgets/account_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/nav_tile.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AccountSection extends StatelessWidget {
  final String userName;
  final String? userSubtitle;
  final VoidCallback onEditUsername;
  final VoidCallback onChangePassword;
  final VoidCallback? onLogout;

  const AccountSection({
    super.key,
    required this.userName,
    this.userSubtitle,
    required this.onEditUsername,
    required this.onChangePassword,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        NavTile(
          leading:
              Icon(Icons.person_outline_rounded, size: 18, color: cs.primary),
          iconBgColor: cs.primary.withValues(alpha: 0.12),
          title: userName.isEmpty ? l.userName : userName,
          subtitle: userSubtitle,
          onTap: onEditUsername,
        ),
        Divider(
            height: 0,
            indent: 63,
            color: cs.outlineVariant.withValues(alpha: 0.4)),
        NavTile(
          leading:
              Icon(Icons.lock_outline_rounded, size: 18, color: cs.secondary),
          iconBgColor: cs.secondary.withValues(alpha: 0.12),
          title: l.changePassword,
          onTap: onChangePassword,
        ),
        if (onLogout != null) ...[
          Divider(
              height: 0,
              indent: 63,
              color: cs.outlineVariant.withValues(alpha: 0.4)),
          NavTile(
            leading: Icon(Icons.logout_rounded, size: 18, color: cs.error),
            iconBgColor: cs.error.withValues(alpha: 0.10),
            title: l.logout,
            onTap: onLogout,
            danger: true,
          ),
        ],
      ],
    );
  }
}
