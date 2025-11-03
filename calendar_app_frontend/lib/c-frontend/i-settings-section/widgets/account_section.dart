// lib/c-frontend/i-settings-section/widgets/account_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/i-settings-section/widgets/nav_tile.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AccountSection extends StatelessWidget {
  final String userName;
  final VoidCallback onEditUsername;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const AccountSection({
    super.key,
    required this.userName,
    required this.onEditUsername,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      children: [
        NavTile(
          leading: const Icon(Icons.person_outline_rounded),
          title: l.userName,
          subtitle: userName,
          onTap: onEditUsername,
        ),
        const Divider(height: 0),
        NavTile(
          leading: const Icon(Icons.lock_outline_rounded),
          title: l.changePassword,
          onTap: onChangePassword,
        ),
        const Divider(height: 0),
        NavTile(
          leading: Icon(Icons.logout_rounded, color: errorColor),
          title: l.logout,
          onTap: onLogout,
          danger: true, // will color title/subtitle via NavTile
        ),
      ],
    );
  }
}
