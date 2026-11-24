import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/access/role_info_screen.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';

/// Read-only business context with links to the existing management flows.
class BusinessOverviewScreen extends StatelessWidget {
  const BusinessOverviewScreen({
    super.key,
    required this.group,
    this.user,
    this.role,
    this.fetchReadSas,
    this.onOpenMembers,
    this.onOpenSettings,
  });

  final Group group;
  final User? user;
  final GroupRole? role;
  final SasFetcher? fetchReadSas;
  final VoidCallback? onOpenMembers;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = l.localeName.toLowerCase().startsWith('es');
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final canOpenRole = user != null && role != null && fetchReadSas != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Negocio' : 'Business'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: AvatarUtils.groupAvatar(context, group.displayPhotoUrl,
                      radius: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (group.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(group.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.groups_outlined,
            title: isSpanish ? 'Miembros' : 'Members',
            value: '${group.userIds.length}',
          ),
          if (role != null) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: role!.icon,
              title: isSpanish ? 'Tu rol' : 'Your role',
              value: roleLabelOf(context, role!),
              onTap: canOpenRole
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => RoleInfoScreen(
                          group: group,
                          user: user!,
                          role: role!,
                          fetchReadSas: fetchReadSas!,
                        ),
                      ))
                  : null,
            ),
          ],
          if (onOpenMembers != null || onOpenSettings != null) ...[
            const SizedBox(height: 20),
            Text(isSpanish ? 'Administración' : 'Management',
                style: text.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (onOpenMembers != null)
              _NavigationRow(
                icon: Icons.people_outline_rounded,
                label: isSpanish ? 'Miembros y roles' : 'Members and roles',
                onTap: onOpenMembers!,
              ),
            if (onOpenSettings != null)
              _NavigationRow(
                icon: Icons.settings_outlined,
                label: isSpanish
                    ? 'Configuración del negocio'
                    : 'Business settings',
                onTap: onOpenSettings!,
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 0,
      minTileHeight: 48,
      leading: Icon(icon, color: cs.primary),
      title: Text(title),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                )),
        if (onTap != null) const Icon(Icons.chevron_right_rounded),
      ]),
      onTap: onTap,
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 0,
        minTileHeight: 48,
        leading: Icon(icon, size: 20),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}
