// lib/presentation/i-settings-section/widgets/account_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/settings/widgets/nav_tile.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AccountSection extends StatelessWidget {
  final String userName;
  final String? userSubtitle;
  final VoidCallback onEditUsername;
  final VoidCallback onChangePassword;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLogout;
  final bool compact;

  const AccountSection({
    super.key,
    required this.userName,
    this.userSubtitle,
    required this.onEditUsername,
    required this.onChangePassword,
    this.onEditProfile,
    this.onLogout,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.startsWith('es');

    if (compact) {
      final displayName = userName.isEmpty ? l.userName : userName;
      return InkWell(
        onTap: onEditUsername,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
                child: Icon(Icons.person_outline_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (userSubtitle != null && userSubtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        userSubtitle!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEditProfile != null)
                TextButton.icon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(isEs ? 'Editar perfil' : 'Edit profile'),
                ),
            ],
          ),
        ),
      );
    }

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
        if (onEditProfile != null) ...[
          Divider(
              height: 0,
              indent: 63,
              color: cs.outlineVariant.withValues(alpha: 0.4)),
          NavTile(
            leading: Icon(Icons.edit_outlined, size: 18, color: cs.primary),
            iconBgColor: cs.primary.withValues(alpha: 0.12),
            title: isEs ? 'Editar perfil' : 'Edit profile',
            onTap: onEditProfile,
          ),
        ],
        Divider(
            height: 0,
            indent: 63,
            color: cs.outlineVariant.withValues(alpha: 0.4)),
        NavTile(
          leading:
              Icon(Icons.lock_outline_rounded, size: 18, color: cs.primary),
          iconBgColor: cs.primary.withValues(alpha: 0.12),
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
