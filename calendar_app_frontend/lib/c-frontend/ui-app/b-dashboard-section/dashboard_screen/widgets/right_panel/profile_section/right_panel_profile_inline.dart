import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/role_info/role_capability_summaries.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/l10n/app_localizations.dart';

typedef SasFetcher = Future<String?> Function(String blobName);

class ProfileInlinePanel extends StatelessWidget {
  const ProfileInlinePanel({
    super.key,
    required this.group,
    required this.user,
    required this.role,
    required this.fetchReadSas,
  });

  final Group group;
  final User user;
  final GroupRole role;
  final SasFetcher fetchReadSas;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final roleLabel = roleLabelOf(context, role);
    final bullets = roleCapabilitySummaries(role, l);

    String displayName() {
      final dn = (user.displayName ?? '').trim();
      if (dn.isNotEmpty) return dn;
      if (user.name.trim().isNotEmpty) return user.name.trim();
      if (user.userName.trim().isNotEmpty) return user.userName.trim();
      final email = user.email.trim();
      return email.contains('@') ? email.split('@').first : 'User';
    }

    String? atUsername() {
      final h = user.userName.trim();
      if (h.isEmpty) return null;
      final at = h.startsWith('@') ? h : '@$h';
      if ((user.displayName ?? '').trim() == at || user.name.trim() == at) {
        return null;
      }
      return at;
    }

    final key = role.wire.toLowerCase().replaceAll('-', '').replaceAll('_', '');
    final capabilityColor = (key == 'member') ? cs.secondary : cs.primary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      user: user,
                      fetchReadSas: fetchReadSas,
                      radius: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (atUsername() != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              atUsername()!,
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: Icon(
                                  role.icon,
                                  size: 18,
                                  color: cs.onPrimary,
                                ),
                                label: Text(roleLabel),
                                labelStyle: tt.bodySmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                backgroundColor: cs.primary,
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.group_rounded,
                                  size: 18,
                                ),
                                label: Text(group.name),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_rounded, color: capabilityColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _headline(l, displayName(), roleLabel, role),
                        style: tt.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bolt_rounded, color: capabilityColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.roleCardTapHint,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...bullets.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: capabilityColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: tt.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _headline(
      AppLocalizations l, String displayName, String roleLabel, GroupRole role) {
    final key = role.wire.toLowerCase().replaceAll('-', '').replaceAll('_', '');
    final text = l.roleCardTapHint;
    if (key == 'owner' || key == 'admin' || key == 'coadmin') {
      return '${l.hey} $displayName — ${l.youAreThe} $roleLabel ${l.ofThisGroup}. ${l.youHaveSuperPowersHere}\n$text';
    }
    return '${l.hey} $displayName — ${l.youAreThe} ${l.member} ${l.ofThisGroup}.\n$text';
  }
}
