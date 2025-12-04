// lib/c-frontend/ui-app/b-dashboard-section/sections/role_info/profile_role_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/l10n/app_localizations.dart';

typedef SasFetcher = Future<String?> Function(String blobName);

class ProfileRoleCard extends StatelessWidget {
  const ProfileRoleCard({
    super.key,
    required this.user,
    required this.role,
    required this.fetchReadSas,
    required this.onTap, // 👈 make it tappable
  });

  final User user;
  final GroupRole role;
  final SasFetcher fetchReadSas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final displayName = _displayName(user);
    final atUsername = _atUsername(user);
    final roleLabel = roleLabelOf(context, role);
    final title = _greetingLine(l, displayName, roleLabel, role);

    return Semantics(
      button: true,
      label: '$displayName, $roleLabel',
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(user: user, fetchReadSas: fetchReadSas, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NameBlock(
                        displayName: displayName,
                        atUsername: atUsername,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 18, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.roleCardTapHint,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayName(User u) {
    final display = (u.displayName ?? '').trim();
    if (display.isNotEmpty) return display;
    final name = (u.name).trim();
    if (name.isNotEmpty) return name;
    final handle = (u.userName).trim();
    if (handle.isNotEmpty) return handle;
    final email = (u.email).trim();
    if (email.contains('@')) return email.split('@').first;
    return 'User';
  }

  String? _atUsername(User u) {
    final handle = (u.userName).trim();
    if (handle.isEmpty) return null;
    final at = handle.startsWith('@') ? handle : '@$handle';
    if ((u.displayName ?? '').trim() == at || (u.name).trim() == at)
      return null;
    return at;
  }

  String _greetingLine(AppLocalizations l, String displayName, String roleLabel,
      GroupRole role) {
    final key = role.wire.toLowerCase().replaceAll('-', '').replaceAll('_', '');
    if (key == 'owner' || key == 'admin' || key == 'coadmin') {
      return '${l.hey} $displayName — ${l.youAreThe} $roleLabel ${l.ofThisGroup}. ${l.youHaveSuperPowersHere}';
    }
    return '${l.hey} $displayName — ${l.youAreThe} ${l.member} ${l.ofThisGroup}.';
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.displayName, required this.atUsername});
  final String displayName;
  final String? atUsername;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
        ),
        if (atUsername != null) ...[
          const SizedBox(height: 2),
          Text(
            atUsername!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
