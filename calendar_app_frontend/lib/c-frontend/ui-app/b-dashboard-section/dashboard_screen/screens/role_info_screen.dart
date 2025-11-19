// lib/c-frontend/ui-app/b-dashboard-section/sections/role_info/role_info_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/role_info/role_capability_summaries.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/l10n/app_localizations.dart';

typedef SasFetcher = Future<String?> Function(String blobName);

class RoleInfoScreen extends StatelessWidget {
  const RoleInfoScreen({
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

    final roleLabel = role.label(l);
    final bullets = RoleCapabilitySummaries.forRole(role, l);

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

    return Scaffold(
      appBar: AppBar(title: Text(roleLabel)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(user: user, fetchReadSas: fetchReadSas, radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + @username
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800, height: 1.1),
                          ),
                        ),
                        finalUsername(atUsername(), tt, cs),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _headline(l, displayName(), roleLabel, role),
                      style: tt.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
              thickness: 1,
              height: 1,
              color: cs.outlineVariant.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text(l.youHaveSuperPowersHere,
              style: role == GroupRole.member
                  ? tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)
                  : tt.bodyMedium?.copyWith(color: cs.onSurface)),
          const SizedBox(height: 12),
          ...bullets.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7, right: 8),
                        decoration: BoxDecoration(
                            color: cs.primary, shape: BoxShape.circle)),
                    Expanded(
                        child: Text(s,
                            style: tt.bodySmall?.copyWith(height: 1.45))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget finalUsername(String? at, TextTheme tt, ColorScheme cs) {
    if (at == null) return const SizedBox.shrink();
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          at,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  String _headline(
      AppLocalizations l, String name, String roleLabel, GroupRole role) {
    final base = '${l.hey} $name — ${l.youAreThe} $roleLabel ${l.ofThisGroup}.';
    if (role == GroupRole.member) return base;
    return '$base ${l.youHaveSuperPowersHere}';
  }
}
