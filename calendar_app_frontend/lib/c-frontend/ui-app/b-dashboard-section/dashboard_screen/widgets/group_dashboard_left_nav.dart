import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupDashboardLeftNav extends StatelessWidget {
  static const double expandedWidth = 240;
  static const double collapsedWidth = 84;

  final Group group;
  final User? user;
  final bool isDark;
  final List<(String, IconData, String)> sections;
  final void Function(String anchor)? onSectionTap;
  final String? selectedAnchor;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const GroupDashboardLeftNav({
    super.key,
    required this.group,
    required this.user,
    required this.isDark,
    required this.sections,
    this.onSectionTap,
    this.selectedAnchor,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final navWidth = collapsed ? collapsedWidth : expandedWidth;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: navWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: collapsed
                              ? l.dashboardNavExpand
                              : l.dashboardNavCollapse,
                          onPressed: onToggleCollapse,
                          icon: Icon(
                              collapsed ? Icons.chevron_right : Icons.chevron_left),
                        ),
                        if (!collapsed)
                          Text(
                            l.dashboardNavTitle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (collapsed)
                      _GroupCompactCard(group: group, isDark: isDark)
                    else
                      _GroupCard(group: group, isDark: isDark),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Column(
                        children: [
                          for (final s in sections) ...[
                            _NavRow(
                              label: s.$1,
                              icon: s.$2,
                              isDark: isDark,
                              onTap: onSectionTap == null
                                  ? null
                                  : () => onSectionTap!(s.$3),
                              isSelected: selectedAnchor == s.$3,
                              collapsed: collapsed,
                            ),
                            if (s != sections.last)
                              Divider(
                                height: 1,
                                thickness: 0.6,
                                color: (isDark
                                        ? AppDarkColors.textSecondary
                                        : AppColors.textSecondary)
                                    .withOpacity(0.25),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (user != null && collapsed)
                      _UserCompactCard(user: user!, isDark: isDark)
                    else if (user != null)
                      _UserCard(user: user!, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool collapsed;

  const _NavRow({
    required this.label,
    required this.icon,
    required this.isDark,
    this.onTap,
    this.isSelected = false,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected
        ? (isDark ? AppDarkColors.primary : AppColors.primary)
        : (isDark ? AppDarkColors.textPrimary : AppColors.textPrimary);
    final bg = isSelected ? fg.withOpacity(0.10) : Colors.transparent;
    final row = InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 14, vertical: 12),
        color: bg,
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: fg),
            if (!collapsed) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
    if (collapsed) {
      return Tooltip(message: label, child: row);
    }
    return row;
  }
}

class _GroupCompactCard extends StatelessWidget {
  final Group group;
  final bool isDark;
  const _GroupCompactCard({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    return Tooltip(
      message: group.name,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: bg.withOpacity(0.92),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: onSurface.withOpacity(0.12),
            backgroundImage:
                (group.photoUrl != null && group.photoUrl!.isNotEmpty)
                    ? NetworkImage(group.photoUrl!)
                    : null,
            child: (group.photoUrl == null || group.photoUrl!.isEmpty)
                ? Icon(Icons.group, color: onSurface)
                : null,
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final bool isDark;
  const _GroupCard({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: bg.withOpacity(0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: group.photoUrl != null && group.photoUrl!.isNotEmpty
                    ? Image.network(group.photoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: onSurface.withOpacity(0.08),
                        child: Icon(Icons.group, color: onSurface, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              group.name,
              style: typo.bodyMedium.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              group.description,
              style: typo.bodySmall.copyWith(
                color: onSurface.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCompactCard extends StatelessWidget {
  final User user;
  final bool isDark;
  const _UserCompactCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    return Tooltip(
      message: user.name,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: bg.withOpacity(0.92),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: onSurface.withOpacity(0.12),
            backgroundImage:
                (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: AppTypography.of(context).bodyMedium.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final bool isDark;
  const _UserCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: bg.withOpacity(0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: onSurface.withOpacity(0.12),
              backgroundImage:
                  (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                      ? NetworkImage(user.photoUrl!)
                      : null,
              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: typo.bodyMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: typo.bodyMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user.userName}',
                    style: typo.caption.copyWith(
                      color: onSurface.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
