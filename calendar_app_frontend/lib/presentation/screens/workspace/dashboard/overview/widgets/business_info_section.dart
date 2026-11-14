import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/screens/workspace/sections/role_info/role_capability_summaries.dart';
import 'package:hexora/presentation/shared/widgets/avatars/user_avatar.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Compact "Información del negocio" content rendered inside the expandable
/// business information section of the mobile dashboard.
///
/// Shows three aligned rows — profile, access permissions and working hours —
/// separated by subtle dividers on a single surface.
class BusinessInfoSection extends StatelessWidget {
  const BusinessInfoSection({
    super.key,
    required this.user,
    required this.role,
    required this.group,
    required this.fetchReadSas,
    required this.onOpenProfile,
    this.onEditBusinessHours,
  });

  final User user;
  final GroupRole role;
  final Group group;
  final SasFetcher fetchReadSas;
  final VoidCallback onOpenProfile;
  final VoidCallback? onEditBusinessHours;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProfileRow(
          user: user,
          role: role,
          fetchReadSas: fetchReadSas,
          onTap: onOpenProfile,
        ),
        _divider(cs),
        _PermissionsRow(role: role),
        _divider(cs),
        _WorkingHoursRow(group: group, onTap: onEditBusinessHours),
      ],
    );
  }

  Widget _divider(ColorScheme cs) => Divider(
        height: 1,
        thickness: 1,
        color: cs.outlineVariant.withValues(alpha: .45),
      );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.user,
    required this.role,
    required this.fetchReadSas,
    required this.onTap,
  });

  final User user;
  final GroupRole role;
  final SasFetcher fetchReadSas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final displayName = _displayName(user);
    final atUsername = _atUsername(user);
    final roleLabel = roleLabelOf(context, role);
    final badgeColor = role.roleChipColor(cs);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            UserAvatar(user: user, fetchReadSas: fetchReadSas, radius: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (atUsername != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      atUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsRow extends StatelessWidget {
  const _PermissionsRow({required this.role});

  final GroupRole role;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _InfoRow(
      icon: Icons.shield_outlined,
      title: l.accessPermissionsTitle,
      subtitle: _accessSubtitle(l, role),
      trailing: _ActionLabel(label: l.viewRolePermissions),
      onTap: () => _showRolePermissionsSheet(context, role),
    );
  }
}

class _WorkingHoursRow extends StatelessWidget {
  const _WorkingHoursRow({required this.group, this.onTap});

  final Group group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final hours = group.businessHours;
    final hasWindow = hours?.isConfigured ?? false;
    final subtitle = hasWindow
        ? l.businessHoursRange(
            hours!.start ?? '--:--',
            hours.end ?? '--:--',
            hours.timezone,
          )
        : l.businessHoursUnset;

    return _InfoRow(
      icon: Icons.schedule_rounded,
      title: l.sectionBusinessHours,
      subtitle: subtitle,
      trailing: onTap == null
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
      onTap: onTap,
    );
  }
}

/// Shared row skeleton: leading icon, title + secondary text, optional trailing.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}


class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurfaceVariant),
      ],
    );
  }
}

String _accessSubtitle(AppLocalizations l, GroupRole role) {
  final key = role.wire.toLowerCase().replaceAll('-', '').replaceAll('_', '');
  switch (key) {
    case 'owner':
      return l.accessFullBusiness;
    case 'admin':
      return l.roleFallbackDescAdmin;
    case 'coadmin':
      return l.roleFallbackDescCoAdmin;
    default:
      return l.roleFallbackDescMember;
  }
}

void _showRolePermissionsSheet(BuildContext context, GroupRole role) {
  final l = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final t = AppTypography.of(context);
  final roleLabel = roleLabelOf(context, role);
  final bullets = roleCapabilitySummaries(role, l);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roleLabel,
                style: t.bodyLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.accessPermissionsTitle,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              ...bullets.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: t.bodyMedium.copyWith(
                            color: cs.onSurface,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _displayName(User u) {
  final display = (u.displayName ?? '').trim();
  if (display.isNotEmpty) return display;
  final name = u.name.trim();
  if (name.isNotEmpty) return name;
  final handle = u.userName.trim();
  if (handle.isNotEmpty) return handle;
  final email = u.email.trim();
  if (email.contains('@')) return email.split('@').first;
  return 'User';
}

String? _atUsername(User u) {
  final handle = u.userName.trim();
  if (handle.isEmpty) return null;
  final at = handle.startsWith('@') ? handle : '@$handle';
  if ((u.displayName ?? '').trim() == at || u.name.trim() == at) {
    return null;
  }
  return at;
}

